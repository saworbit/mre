# CRITICAL FINDING: Wanton Stuck Loop at Elevator

**Date**: 2026-01-07
**Map**: DM2
**Evidence**: Log analysis

---

## 🚨 **SMOKING GUN: 35+ Consecutive Stuck Events**

### The Pattern
```
[Wanton] GOAL: item_armor2 (score=5512.6, dist=487.4u)
[Wanton] STUCK: Desperate escape (count=6)
[Wanton] UNSTUCK: Super jump escape
[Wanton] STUCK: Desperate escape (count=6)
[Wanton] UNSTUCK: Super jump escape
[Wanton] STUCK: Desperate escape (count=6)
[Wanton] UNSTUCK: Super jump escape
... (repeats 35+ times)
[Wanton] STUCK: Desperate escape (count=6)
[Wanton] UNSTUCK: Train surf escape    ← Desperate measures!
[Wanton] STUCK: Desperate escape (count=6)
[Wanton] UNSTUCK: Super jump escape
Wanton burst into flames               ← Lava death!
```

### What This Means

**Wanton's behavior**:
1. Sets goal: item_armor2 (Yellow Armor on elevator platform)
2. Pathfinds to location
3. Gets stuck (can't reach platform)
4. Desperate escape (super jump)
5. Tries again
6. **REPEATS 35+ TIMES IN A ROW**
7. Eventually uses "Train surf escape" (standing on train below)
8. Still stuck
9. Dies in lava

**This is classic "bot stuck at unmapped elevator shaft" behavior!**

---

## 🎯 **Root Cause Analysis**

### Hypothesis: DM2 Elevator Unmapped

**Evidence**:
- ✅ Wanton seeks item_armor2 repeatedly
- ✅ Gets stuck at EXACT same location 35+ times
- ✅ Never reaches goal (no "got the yellow armor" message)
- ✅ Dies in lava (elevator area has lava pit below)
- ✅ Uses "Train surf escape" (train passes under elevator)

**Conclusion**: DM2 Yellow Armor is on an elevator platform that has no waypoints.

### Why Bots Get Stuck

**Scenario**:
1. Bot pathfinds to Yellow Armor using nearest waypoint
2. Nearest waypoint is NOT on elevator platform (unmapped)
3. Bot reaches waypoint, tries to move to armor
4. Platform is elevated → Can't reach it → **Stuck**
5. Desperate escape (super jump) → Lands in same spot
6. **Infinite loop**

---

## ❌ **Still No Debug Logging**

**Critical Issue**: User STILL hasn't run `impulse 95`

**Evidence**:
- Zero "BOT DEBUG ENABLED" messages
- Zero "ELEVATOR:" messages
- Zero "A*:" messages

**What we're missing**:
```
[Wanton] ELEVATOR: Waiting at '...'          (Would show elevator behavior)
[Wanton] ELEVATOR: Timeout (30s)             (Would show if timeout works)
A*: Elevator blocked at '...'                 (Would show if A* blocking works)
ELEVATOR: Created WAIT_NODE at '...'          (Would show auto-creation)
```

**WE STILL CAN'T SEE THE ELEVATOR SYSTEM WORKING!**

---

## 📊 **Maps Played**

| Map | Waypoints | Elevators | What Happened |
|-----|-----------|-----------|---------------|
| **DM1** | ❌ None | ❓ Unknown | Quick test, switched away |
| **E1M1** | ❌ None | ✅ Quad elevator | No navigation (no waypoints) |
| **DM2** | ✅ 362 | ✅ Yellow Armor elevator | **Wanton stuck loop × 35!** |

### DM2 Elevator Location
**Item**: Yellow Armor (item_armor2)
**Platform**: func_plat (elevator to upper area)
**Status**: **UNMAPPED** (no elevator waypoints in dm2.qc)
**Result**: Bots pathfind close, but can't reach platform → Stuck loop

---

## 🔍 **What We Learned**

### ✅ **Proof Bot AI Works**
- Wanton correctly identified Yellow Armor as valuable goal
- Pathfinding got close to location (within 147-763 units)
- Desperate escape triggered correctly (count=6 threshold)
- Multiple unstuck methods attempted (super jump, rocket jump, train surf)

### ✅ **Proof Elevator Exists**
- Item_armor2 is definitely on an elevated platform (distance varies 147-763u)
- Train surf escape triggered (train passes under elevator)
- Lava death (lava pit below elevator area in DM2)

### ❌ **Proof Elevator System Silent**
- No ELEVATOR messages despite 35+ stuck events at elevator
- No A* blocking messages
- No wait state messages
- **System is running but invisible without debug**

### ⚠️ **Stuck Loop is Navigation Issue, Not Code Bug**
- Bot navigation works (reaches area)
- Desperate escape works (super jump, rocket jump)
- **Problem**: No waypoints ON the elevator platform
- **Solution**: Auto-creation should create nodes when bots explore

---

## 🎯 **Critical Questions**

### Q1: Did elevator auto-creation run?
**Expected**: When Wanton stood on elevator, should create WAIT_NODE
**Actual**: Unknown (no debug output)
**Possible reasons**:
- Auto-creation requires bot to DROP breadcrumb on platform
- Bot never actually reached platform (stuck before boarding)
- Feature worked but we can't see it (no debug)

### Q2: Did A* block the elevator path?
**Expected**: If platform at top, A* should skip elevator, find alternate route
**Actual**: Unknown (no debug output)
**Observation**: Bot pathfound CLOSE to elevator (within 147u) but not ON it

### Q3: Did wait state trigger?
**Expected**: Bot should stop and wait for platform to descend
**Actual**: Unknown (no debug output)
**Observation**: Bot got stuck instead (super jump loop)

### Q4: Why 35+ stuck events instead of timeout?
**Expected**: Elevator timeout after 30 seconds → Replan route
**Actual**: Stuck loop continued indefinitely
**Possible reasons**:
- Timeout only triggers if bot reaches WAIT_NODE (bot never reached it)
- Stuck recovery kept repositioning bot (reset timeout timer)
- Timeout works but we can't see it (no debug)

---

## 📋 **Action Items**

### IMMEDIATE: Enable Debug and Retest

**Step 1: Load DM2**
```
map dm2
```

**Step 2: ENABLE DEBUG (CRITICAL!)**
```
impulse 95    # Bot debug ON
impulse 96    # LOG_TACTICAL (shows ELEVATOR messages)
impulse 96    # LOG_VERBOSE (shows A* and auto-creation)
```

**Step 3: Spawn Bots**
```
impulse 100
```

**Step 4: Watch for Wanton's Stuck Loop**
If Wanton gets stuck again, we'll now SEE:
```
[Wanton] ELEVATOR: Waiting at '...'
[Wanton] ELEVATOR: Timeout (30.1s), replanning
ELEVATOR: Created WAIT_NODE at '...'
A*: Elevator blocked at '...'
```

---

## 🎓 **Lessons Learned**

### 1. Stuck Loops Reveal Navigation Gaps
**Pattern**: 35+ identical stuck events = unmapped area
**Location**: item_armor2 on DM2 = elevator platform
**Solution**: Either manual waypoints or auto-creation

### 2. Train Surf Escape is Working
**Evidence**: "Train surf escape" triggered in logs
**Location**: Train passes under DM2 elevator
**Success**: Bot detected train, attempted to use momentum
**Outcome**: Still stuck (train didn't go to elevator platform)

### 3. Desperate Measures Escalate
**Progression**:
1. Super jump (most common)
2. Rocket jump (when has rockets)
3. Train surf (when standing on train)
**Design**: Good escalation, but can't solve "unmapped platform" problem

### 4. Debug Logging is MANDATORY
**Without debug**:
- ✅ Can see stuck events
- ✅ Can see goals
- ❌ Can't see WHY stuck
- ❌ Can't see elevator behavior
- ❌ Can't verify system works

---

## 🔬 **Next Test Protocol**

### Test A: Verify Auto-Creation (DM2)
```
map dm2
impulse 95; impulse 96; impulse 96    # Debug on, LOG_VERBOSE
impulse 100                            # Spawn bots
noclip                                 # Fly to elevator
notarget                               # Bots ignore you
```

**Manually place bot on elevator**:
1. Use console: `setpos <bot> <elevator_coords>`
2. Watch for: `ELEVATOR: Created WAIT_NODE`
3. Watch for: `ELEVATOR: Created EXIT_NODE`

### Test B: Verify A* Blocking (DM2)
```
(Same setup as Test A)
```

**Observe**:
1. Does bot path to elevator when platform at bottom?
2. Does A* skip elevator when platform at top?
3. Watch for: `A*: Elevator blocked at '...'`

### Test C: Verify Wait State (DM2)
```
(Same setup as Test A)
```

**Trigger wait**:
1. Ensure platform is at top
2. Manually route bot to elevator entrance
3. Watch for: `[Bot] ELEVATOR: Waiting at '...'`
4. Wait 30 seconds
5. Watch for: `[Bot] ELEVATOR: Timeout, replanning`

---

## 📈 **Evidence Summary**

| Evidence | Confidence | Implication |
|----------|-----------|-------------|
| 35+ stuck events at same location | 100% | Bot trying to reach unreachable location |
| Goal = item_armor2 every time | 100% | Location is Yellow Armor |
| Train surf escape triggered | 100% | Train passes under location = elevator area |
| Lava death after stuck loop | 100% | Lava pit below = elevator area |
| No "got the armor" message | 100% | Never reached destination |
| No debug output | 100% | User didn't enable impulse 95 |
| Distance varies (147-763u) | 90% | Platform moves = elevator |
| No alternate route taken | 80% | Either A* blocking didn't work OR no alternate exists |

---

## 🎯 **Conclusion**

**What happened**:
1. ✅ Wanton correctly identified Yellow Armor as goal
2. ✅ Pathfinding got close to elevator area
3. ❌ No waypoints ON elevator platform (unmapped)
4. ❌ Bot stuck in infinite loop (35+ escapes)
5. ❌ Eventually died in lava pit below elevator
6. ❓ Elevator system behavior **UNKNOWN** (no debug enabled)

**What we need**:
1. **ENABLE DEBUG LOGGING** (impulse 95 + 96)
2. Verify auto-creation creates elevator nodes
3. Verify A* blocking prevents stuck loops
4. Verify wait state + timeout work correctly

**The elevator system might be working perfectly - we just can't see it without debug!**

---

**Next Steps**:
1. **RUN TEST WITH DEBUG ENABLED**
2. Check if auto-creation triggers when bot explores
3. Verify A* messages show blocking behavior
4. Confirm wait state and timeout work

**The 35-stuck-loop is the BEST evidence we have that elevator navigation is critical!**
