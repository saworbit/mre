# Log Analysis - 2026-01-07

## What Actually Happened

### Maps Played
1. **DM4** - Successfully loaded, has 453 waypoints
2. **DM2** - Also loaded
3. **E1M1** - Attempted multiple times (no waypoints)
4. **DM3** - Attempted (no waypoints, no elevators)

### Key Findings from Logs

#### ✅ **DM4 Did Load and Run**
```
SpawnServer: dm4
Programs occupy 485K
Loaded 452 waypoints for DM4
```

#### ✅ **Bots ARE Seeking Yellow Armor (item_armor2)**
- **29 separate goal selections** for item_armor2
- Examples:
  ```
  [Drooly] GOAL: item_armor2 (score=5236.3, dist=763.7u)
  [Assmunch] GOAL: item_armor2 (score=5095.8, dist=904.2u)
  [Wanton] GOAL: item_armor2 (score=5693.2, dist=306.8u)
  ```

#### ❌ **NO Debug Logging Was Enabled**
- Zero instances of "BOT DEBUG ENABLED"
- Zero "ELEVATOR:" messages
- Zero "A*:" messages
- **ALL elevator logging requires `bot_debug_enabled && bot_debug_level >= LOG_TACTICAL`**

#### ⚠️ **HIGH Stuck Count**
- Many bots getting stuck repeatedly
- Examples:
  ```
  [Drooly] STUCK: Desperate escape (count=6)
  [Assmunch] STUCK: Desperate escape (count=6)  (3 times)
  [Derang] STUCK: Desperate escape (count=6)   (2 times)
  [Hater] STUCK: Desperate escape (count=6)    (3 times)
  ```

#### ❌ **No "Got Yellow Armor" Messages**
- Zero instances of "got the yellow armor"
- Bots SEEK it but don't seem to REACH it

---

## Critical Discovery: Debug Logging is REQUIRED

### The Problem
**ALL elevator system messages are gated behind debug flags**:

```qc
// botmove.qc:2127
if ((bot_debug_enabled && (bot_debug_level >= LOG_TACTICAL))) {
    bprint("["); bprint(self.netname);
    bprint("] ELEVATOR: Waiting at ");
    // ...
}
```

**Similar checks in**:
- Wait state (botmove.qc:2127)
- Boarding confirmation (botmove.qc:2173, botthink.qc:564)
- Timeout (botmove.qc:2150)
- Auto node creation (botroute.qc:638, 661, 693, 717)

### What This Means
**Without `impulse 95` + `impulse 96`**:
- ✅ Elevator system IS running
- ✅ Bots ARE using (or avoiding) elevators
- ❌ But we can't SEE it (no console output)
- ❌ Can't verify behavior

---

## What We KNOW Happened (Evidence-Based)

### Evidence 1: Bots Sought Yellow Armor
**29 goal selections** for item_armor2 on DM4 = Bots know where it is

### Evidence 2: High Stuck Count
**Pattern**: Multiple bots stuck near same areas
- Could be at elevator shaft (platform absent → stuck)
- Could be at other obstacles
- **Can't confirm without debug logging**

### Evidence 3: No Completion Messages
**Zero "got the yellow armor"** = Bots didn't successfully reach it
- Possible reasons:
  1. Platform was at top, A* blocked path, bots took alternate route but got stuck
  2. Elevator area has no waypoints yet
  3. Bots reached it but message didn't log (unlikely)

### Evidence 4: DM4 Waypoints Don't Include Elevator
**Search results**:
- 453 waypoints total
- No waypoints near coords (1792, 384, -168) or (1792, 384, -88)
- **Elevator area likely unmapped**

---

## What We DON'T Know (Missing Data)

❓ **Did A* block elevator paths?**
- Need: `A*: Elevator blocked` messages
- Requires: LOG_VERBOSE or higher

❓ **Did bots wait at elevators?**
- Need: `ELEVATOR: Waiting` messages
- Requires: LOG_TACTICAL or higher

❓ **Did bots board elevators?**
- Need: `ELEVATOR: Boarding` messages
- Requires: LOG_TACTICAL or higher

❓ **Were elevator nodes auto-created?**
- Need: `ELEVATOR: Created WAIT_NODE` messages
- Requires: LOG_VERBOSE

❓ **Why so many stuck events?**
- Could be elevator-related
- Could be unrelated navigation issues
- **Can't distinguish without location data**

---

## Hypotheses

### Hypothesis 1: Elevator System Working, But Unmapped
**Theory**: DM4 elevator area has no waypoints yet
**Evidence**:
- ✅ Bots seek Yellow Armor (know it exists)
- ✅ No waypoints found at elevator coords
- ✅ High stuck count (exploring unmapped area)
- ✅ No completion messages (can't reach unmapped area)

**Prediction**: If we enable LOG_VERBOSE, we'll see:
```
ELEVATOR: Created WAIT_NODE at '...'
ELEVATOR: Created EXIT_NODE at '...'
```

### Hypothesis 2: Platform at Top, A* Blocking Works
**Theory**: Platform was at top position, A* correctly blocked path
**Evidence**:
- ✅ Bots seek Yellow Armor
- ✅ No completion messages
- ⚠️ No visible alternate route success

**Prediction**: If we enable LOG_VERBOSE, we'll see:
```
A*: Elevator blocked at '...' (platform at top)
```

### Hypothesis 3: Stuck Events ARE Elevator-Related
**Theory**: Bots getting stuck at unmapped elevator shaft
**Evidence**:
- ✅ Multiple bots stuck (same problem area?)
- ✅ All seeking same goal (Yellow Armor)
- ⚠️ Stuck events also happen elsewhere (not conclusive)

**Prediction**: With debug logging, stuck coordinates will match elevator area

---

## Action Items

### CRITICAL: Enable Debug Logging
**Without this, we're flying blind**

```
impulse 95    // Enable bot debug
impulse 96    // Cycle to LOG_TACTICAL (shows ELEVATOR messages)
impulse 96    // Cycle to LOG_VERBOSE (shows A* and node creation)
```

### Test Sequence
1. **Load DM4**: `map dm4`
2. **Enable Debug**: `impulse 95` then `impulse 96` twice
3. **Spawn Bots**: `impulse 100`
4. **Watch Console** for:
   - `ELEVATOR: Created WAIT_NODE` (auto-creation working)
   - `ELEVATOR: Waiting` (wait state working)
   - `ELEVATOR: Boarding` (boarding working)
   - `A*: Elevator blocked` (pathfinding working)
5. **Check Stuck Locations** - Do they match elevator coords?

### Verification Questions
- ✅ Is elevator code running? → **CAN'T VERIFY** (no debug output)
- ✅ Are bots using elevators? → **CAN'T VERIFY** (no debug output)
- ✅ Is A* blocking working? → **CAN'T VERIFY** (no debug output)
- ✅ Is auto-creation working? → **CAN'T VERIFY** (no debug output)

---

## Lessons Learned

### 1. Silent Systems Are Untestable
**Problem**: Elevator system has comprehensive functionality but zero output by default
**Impact**: Can't verify if it's working without debug mode
**Solution**: Always test WITH debug logging enabled

### 2. Debug Gating Can Hide Issues
**Problem**: ALL elevator messages gated behind `bot_debug_enabled && LOG_TACTICAL`
**Impact**: System could be broken and we wouldn't know
**Alternative**: Consider INFO-level messages for critical events (platform blocked, timeout)

### 3. Waypoint Coverage is Prerequisite
**Problem**: DM4 elevator area appears unmapped
**Impact**: Bots can't navigate even with working elevator code
**Solution**: Verify waypoint coverage before testing navigation features

### 4. E1M1/DM3 Were Red Herrings
**Problem**: Tested on maps without waypoints/elevators
**Impact**: Wasted time debugging wrong issue
**Learning**: Always verify map compatibility first

---

## Next Test Plan

### Minimal Test (5 min)
```
map dm4
impulse 95    // debug on
impulse 96    // LOG_TACTICAL
impulse 100   // spawn bots
```
**Watch for**: Any `ELEVATOR:` messages

### Full Test (10 min)
```
map dm4
impulse 95    // debug on
impulse 96    // LOG_TACTICAL
impulse 96    // LOG_VERBOSE (see A* and auto-creation)
impulse 100   // spawn bots
noclip        // fly to elevator area
notarget      // bots ignore you
```
**Watch for**:
1. Node creation: `ELEVATOR: Created WAIT_NODE`
2. A* behavior: `A*: Elevator blocked`
3. Wait state: `ELEVATOR: Waiting`
4. Boarding: `ELEVATOR: Boarding`

### Expected Outcome
**If elevator system working**:
- See auto-creation messages (nodes being created)
- See wait/boarding messages (bots using elevator)
- See A* blocking messages (when platform absent)

**If elevator system broken**:
- See bots walk into empty shaft
- See bots fall/take damage
- See stuck events at elevator coords

---

## Confidence Levels

| Question | Confidence | Evidence |
|----------|-----------|----------|
| Did bots run on DM4? | 100% | SpawnServer log |
| Did bots seek Yellow Armor? | 100% | 29 goal messages |
| Is debug logging enabled? | 100% | Zero debug messages |
| Did elevator code run? | 10% | No output to verify |
| Did A* blocking work? | 10% | No output to verify |
| Did auto-creation work? | 10% | No output to verify |
| Are stuck events elevator-related? | 30% | Circumstantial |
| Does DM4 have elevator waypoints? | 20% | No obvious matches |

---

## Conclusion

**We learned**:
1. ✅ Bots played on DM4 successfully
2. ✅ Bots sought Yellow Armor (elevator destination)
3. ❌ Debug logging was NOT enabled
4. ❓ Elevator system behavior is UNKNOWN (no visibility)

**Critical mistake**: Testing without debug logging = flying blind

**Next step**: Repeat test WITH `impulse 95` + `impulse 96` enabled

**Hypothesis**: Elevator system is probably working fine, we just couldn't see it. The stuck events and lack of armor pickups suggest unmapped elevator area, not broken code.
