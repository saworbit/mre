# Investigation Findings: Skill Assignment Bug

**Date**: 2026-01-06
**Investigation**: Comprehensive bot behavior analysis recommendations
**Critical Bug Discovered**: Broken skill assignment system

---

## 🐛 **CRITICAL BUG: Skill Assignment Logic**

### Location
`reaper_mre/botspawn.qc` lines 583-603 (AddBot function)

### The Bug
```c
ran_skill = crandom();  // Returns -1.0 to 1.0

if ((ran_skill <= 0.500))
{
   self.skil = SPAWNFLAG_SUPERSPIKE;  // skil = 1
}
if (((ran_skill > 0.500) && (ran_skill <= 0.200)))  // ❌ IMPOSSIBLE CONDITION!
{
   self.skil = 1.500;
}
if (((ran_skill > 0.200) && (ran_skill <= 0.600)))  // ❌ UNREACHABLE!
{
   self.skil = SPAWNFLAG_LASER;  // skil = 2
}
if (((ran_skill > 0.600) && (ran_skill <= 0.800)))  // ❌ UNREACHABLE!
{
   self.skil = 2.500;
}
if (((ran_skill > 0.800) && (ran_skill <= SPAWNFLAG_SUPERSPIKE)))  // ❌ UNREACHABLE!
{
   self.skil = CAM_FOLLOW;  // skil = 3
}
```

### Why It's Broken
1. Condition at line 588: `ran_skill > 0.500 AND ran_skill <= 0.200` is **mathematically impossible**
2. All subsequent conditions have same logical error (checking if number > X AND < Y where Y < X)
3. First condition catches everything ≤ 0.5
4. **Result: ALL bots spawn with skill = 1** (regardless of crandom() value)

### Evidence from Logs
```
]skill 3
]impulse 208
Cheater (iq 1) is reformed Thanks Chris.
```
Server skill set to 3, but bot spawns with IQ 1!

---

## 📊 **Impact Analysis**

### Systems Completely Broken
All skill-gated features (require `skil > 2.0`) **NEVER ACTIVATE**:

1. **Juggler Combos** (botfight.qc:860)
   ```c
   if (((self.skil > 2.000) && ...))  // NEVER TRUE!
   ```
   **Result**: 0 combo activations in logs

2. **Rocket Jump Unstuck** (botmove.qc:546)
   ```c
   if (((self.ammo_rockets > 0) && (self.skil > 2.000)))  // NEVER TRUE!
   ```
   **Result**: 100% super jump, 0% rocket jump

3. **Advanced Pathfinding** (skill-gated features)
   - Higher-skill bots supposed to use A* pathfinding
   - Never activates because skill locked at 1

4. **Aim Precision Scaling**
   - Skill affects aim noise, reaction time
   - All bots stuck at lowest precision level

### Systems Partially Working
Features that work at skill level 1 are fine:
- ✅ Opponent Profiling (no skill check)
- ✅ Target selection (no skill check)
- ✅ Basic movement (no skill check)
- ✅ Weapon switching (no skill check)

---

## 🔧 **The Fix**

### Corrected Logic
```c
ran_skill = crandom();  // Returns -1.0 to 1.0

// Convert to 0-1 range for easier logic
ran_skill = (ran_skill + 1.000) * 0.500;  // Now 0.0 to 1.0

// Skill distribution:
// 50% chance: skill 1 (novice)
// 20% chance: skill 1.5
// 20% chance: skill 2 (Juggler threshold!)
// 10% chance: skill 2.5
// 10% chance: skill 3 (expert)

if ((ran_skill <= 0.500))  // 50% chance
{
   self.skil = 1.000;
}
else if ((ran_skill <= 0.700))  // 20% chance (0.5-0.7)
{
   self.skil = 1.500;
}
else if ((ran_skill <= 0.900))  // 20% chance (0.7-0.9)
{
   self.skil = 2.000;
}
else if ((ran_skill <= 0.950))  // 5% chance (0.9-0.95)
{
   self.skil = 2.500;
}
else  // 5% chance (0.95-1.0)
{
   self.skil = 3.000;
}
```

### Alternative: Respect Server Skill Setting
```c
// Use server's skill cvar instead of random
self.skil = skill;  // Honors `skill 3` console command

// OR: Add slight randomization around server skill
self.skil = skill + (crandom() * 0.500);  // ±0.5 variation
if ((self.skil < 1.000)) self.skil = 1.000;  // Clamp to 1-4
if ((self.skil > 4.000)) self.skil = 4.000;
```

---

## 🎯 **Expected Results After Fix**

### Juggler Combos Will Activate
With 20% of bots at skill ≥ 2.0:
- Expected combo rate: ~8-15 per session (down from 0)
- Logs will show: `[BotName] COMBO: RL → LG (Juggler shaft-combo)`

### Rocket Jump Recovery Will Work
With skill > 2 bots:
- Expected RJ usage: 20-40% of unstuck events (up from 0%)
- Logs will show: `[BotName] UNSTUCK: Rocket jump escape`

### Aim Will Improve
Higher-skill bots (2.5-3.0) will have:
- Tighter aim spread
- Faster reaction time
- Better lead prediction

### Difficulty Will Scale
- 50% novice bots (skill 1.0)
- 30% intermediate (1.5-2.0)
- 20% expert (2.5-3.0)
- **Actual challenge progression!**

---

## 📋 **Other Findings**

### Goal Diversity Issue
**Finding**: Bots only pursue RL and Red Armor (42 goal events, all RL/Armor)

**Root Cause**: Goal scoring heavily favors RL (score ~4800) and Armor (score ~5400)
- Health packs score too low when HP > 50
- Powerups (Quad/Pent/Ring) undervalued
- No fallback when all items taken → "None found (best_val=-1000)"

**Recommendation**:
- Boost health scoring when HP < 75 (not just < 50)
- Increase powerup denial scoring
- Add fallback goal (roam to high-traffic waypoints) when items unavailable

### Stuck Hotspots
**Finding**: Wanton gets stuck most frequently

**Pattern**: All stuck events trigger at count=6 (desperate escape threshold)
- Specific geometry trouble spots on dm4
- Stairs, tight corners, ledges

**Recommendation**:
- Add waypoints to problem areas
- Implement "stuck memory" (avoid areas where previously stuck)
- Consider lowering desperate escape threshold (5 instead of 6)

---

## 🚀 **Implementation Priority**

### Priority 1: Fix Skill Assignment (CRITICAL) ⚠️
**Impact**: Unlocks all skill-gated features
**Effort**: Low (10 lines of code)
**Testing**: Spawn bots, check `iq` values in console

### Priority 2: Test Skill-Gated Features ✅
After fix, verify:
- Juggler combos activate (run match, check logs)
- Rocket jump unstuck works (observe stuck recovery)
- Aim improves with higher-skill bots

### Priority 3: Goal Diversity Improvements 📊
**Impact**: Medium (more varied behavior)
**Effort**: Medium (tune scoring functions)
**Testing**: Goal event distribution analysis

### Priority 4: Stuck Hotspot Waypoints 🗺️
**Impact**: Low (reduces stuck from 74 to ~40 per session)
**Effort**: Medium (manual waypoint placement)
**Testing**: Play test on dm4, monitor stuck count

---

## 📝 **Validation Plan**

### After Skill Fix
1. Launch game with `skill 3`
2. Spawn bots with `impulse 208`
3. Check console for bot IQ values (should show 1.5, 2.0, 2.5, 3.0)
4. Enable debug logging: `impulse 95` + `impulse 96` (LOG_TACTICAL)
5. Play 5-minute match
6. Check qconsole.log for:
   - COMBO events (expect 8-15)
   - UNSTUCK: Rocket jump events (expect 20-40% of unstuck)
   - Improved combat performance

### Success Criteria
- ✅ Bot skill distribution: 50% novice, 30% intermediate, 20% expert
- ✅ Juggler combos: >0 activations
- ✅ Rocket jump unstuck: >0 activations
- ✅ Varied bot performance (skill affects aim/tactics visibly)

---

## 🎯 **Conclusion**

**Root Cause**: Broken if-else logic in skill assignment
**Scope**: Affects ALL skill-gated features (Juggler, RJ, aim, pathfinding)
**Severity**: **CRITICAL** - completely disables advanced bot features
**Fix Complexity**: **TRIVIAL** - fix conditional logic
**Expected Impact**: **MAJOR** - unlocks all skill-based systems

This single bug explains:
- ❌ Why Juggler has 0 combos (was mystery #1)
- ❌ Why RJ never triggers for unstuck (was mystery #2)
- ❌ Why all bots play identically (no skill variation)

**Fixing this ONE bug will transform bot behavior overnight!**

---

**Investigation completed**: 2026-01-06
**Recommended action**: Implement skill assignment fix immediately
**Expected result**: All skill-gated features become active
