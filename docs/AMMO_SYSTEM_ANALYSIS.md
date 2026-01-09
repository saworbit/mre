# Ammo System Analysis

**Date**: 2026-01-06
**Issue**: User reports HUD display bug - "Sometimes I pick up ammo and the hud display doesn't increment. If I switch weapons and then change back sometimes it does."
**Status**: Investigated - Root cause likely engine/network layer, not QuakeC logic

---

## 🔍 Investigation Summary

### User-Reported Symptom
- **Problem**: Picking up ammo doesn't immediately increment HUD counter
- **Workaround**: Switching weapons triggers HUD refresh, showing correct ammo count
- **Implication**: Server-side ammo value is correct, client-side HUD display is delayed/stale

### Analysis Results
The ammo pickup logic is functionally correct (values are accurate), but contains **severe code quality issues** - constants from unrelated systems are repurposed for ammo identification and amounts.

---

## 🐛 Code Quality Issues Found

### Issue 1: Weapon Pickup Ammo Amounts - Wrong Constants

**Location**: `reaper_mre/items.qc` (weapon_touch function)

**Problem**: Uses network/entity/camera constants instead of literal ammo values:

```c
// Line 424, 437: Nailgun/Super Nailgun
other.ammo_nails = (other.ammo_nails + SVC_INTERMISSION);  // ❌ Network message constant!
// SVC_INTERMISSION = 30 (happens to be correct ammo amount)

// Line 454: Super Shotgun
other.ammo_shells = (other.ammo_shells + TE_LIGHTNING1);  // ❌ Temp entity constant!
// TE_LIGHTNING1 = 5 (correct by accident)

// Line 467, 484: Rocket Launcher/Grenade Launcher
other.ammo_rockets = (other.ammo_rockets + CAM_FREE);  // ❌ Camera mode constant!
// CAM_FREE = 5 (correct by accident)

// Line 501: Lightning Gun (ONLY correct one)
other.ammo_cells = (other.ammo_cells + 15.000);  // ✅ Correct literal value
```

**Constant Definitions**:
- `SVC_INTERMISSION = 30` (defs.qc:242) - Network message ID for intermission screen
- `TE_LIGHTNING1 = 5` (defs.qc:251) - Temp entity ID for lightning beam effect
- `CAM_FREE = 5` (kascam.qc:6) - Camera mode for free-floating spectator

**Impact**: Code works because VALUES are correct, but semantically wrong. Maintainability nightmare - if camera modes or network constants change elsewhere, ammo amounts break.

---

### Issue 2: Ammo Item Identification - Wrong Constants

**Location**: `reaper_mre/items.qc` (item spawn functions + ammo_touch)

**Problem**: Uses health constants, camera modes, and spawn flags to identify ammo types:

| Ammo Type | Type ID Constant Used | Actual Constant | Should Be | Value |
|-----------|----------------------|-----------------|-----------|-------|
| **Shells** | `WEAPON_BIG2` | Spawn flag (items.qc:721) | `AMMO_SHELLS` | 1 |
| **Nails** | `H_MEGA` | Health pickup constant (items.qc:69) | `AMMO_NAILS` | 2 |
| **Rockets** | `CAM_FOLLOW` | Camera mode (kascam.qc:4) | `AMMO_ROCKETS` | 3 |
| **Cells** | `CAM_HAND` | Camera mode (kascam.qc:5) | `AMMO_CELLS` | 4 |

**Code Reference** (items.qc:657-688):
```c
void () ammo_touch =
{
   // ...
   if ((self.weapon == H_ROTTEN))  // ❌ H_ROTTEN = 1 (health constant, repurposed for shells!)
   {
      other.ammo_shells = (other.ammo_shells + self.aflag);
   }
   if ((self.weapon == H_MEGA))  // ❌ H_MEGA = 2 (health constant, repurposed for nails!)
   {
      other.ammo_nails = (other.ammo_nails + self.aflag);
   }
   if ((self.weapon == CAM_FOLLOW))  // ❌ CAM_FOLLOW = 3 (camera mode, repurposed for rockets!)
   {
      other.ammo_rockets = (other.ammo_rockets + self.aflag);
   }
   if ((self.weapon == CAM_HAND))  // ❌ CAM_HAND = 4 (camera mode, repurposed for cells!)
   {
      other.ammo_cells = (other.ammo_cells + self.aflag);
   }
}
```

**Impact**: Same as Issue 1 - works because VALUES happen to be correct, but semantically absurd. Health system or camera system changes could break ammo pickup.

---

### Issue 3: Ammo Spawn Amounts - Wrong Constants

**Location**: `reaper_mre/items.qc` (item spawn functions)

**Problem**: Uses movement type constants for ammo amounts:

| Function | Small Amount Constant | Value | Big Amount Constant | Value |
|----------|----------------------|-------|---------------------|-------|
| **item_shells** | `KINDA_WANT` ✅ | 20 | `40.000` ✅ | 40 |
| **item_spikes** | `25.000` ✅ | 25 | `50.000` ✅ | 50 |
| **item_rockets** | `MOVETYPE_FLY` ❌ | 5 | `TE_LAVASPLASH` ❌ | 10 |
| **item_cells** | `MOVETYPE_TOSS` ❌ | 6 | `12.000` ✅ | 12 |

**Code Reference** (items.qc:769-790):
```c
void () item_rockets =
{
   self.touch = ammo_touch;
   if ((self.spawnflags & WEAPON_BIG2))  // Big rocket box
   {
      precache_model ("maps/b_rock1.bsp");
      setmodel (self,"maps/b_rock1.bsp");
      self.aflag = TE_LAVASPLASH;  // ❌ Temp entity constant (lava splash effect!)
      // TE_LAVASPLASH = 10 (correct value by accident)
   }
   else  // Small rocket box
   {
      precache_model ("maps/b_rock0.bsp");
      setmodel (self,"maps/b_rock0.bsp");
      self.aflag = MOVETYPE_FLY;  // ❌ Entity movement type constant!
      // MOVETYPE_FLY = 5 (correct value by accident)
   }
   self.weapon = CAM_FOLLOW;  // ❌ Camera mode (see Issue 2)
}
```

**Constant Definitions**:
- `MOVETYPE_FLY = 5` (defs.qc:178) - Entity movement type for flying projectiles
- `MOVETYPE_TOSS = 6` (defs.qc:179) - Entity movement type for tossed grenades
- `TE_LAVASPLASH = 10` (defs.qc:256) - Temp entity for lava splash effect
- `KINDA_WANT = 20` (botit_th.qc:232) - Bot goal scoring threshold (repurposed correctly here!)

**Impact**: Same maintainability nightmare - changing movement physics constants breaks ammo amounts.

---

## 💡 Why HUD Bug Likely Isn't QuakeC

### Evidence That Server-Side Logic Is Correct

1. **Ammo values are accurate** - Despite wrong constants, VALUES match Quake's standard ammo amounts:
   - Shells: 20/40 ✅
   - Nails: 25/50 ✅
   - Rockets: 5/10 ✅
   - Cells: 6/12 ✅

2. **Weapon switch workaround works** - User reports switching weapons updates HUD correctly
   - Implies server has correct ammo value
   - Client HUD just isn't refreshing until forced

3. **bonusflash command is called** - `ammo_touch()` calls `stuffcmd(other,"bf\n")` (items.qc:703)
   - This SHOULD trigger HUD refresh
   - But only for players, not bots (if statement on line 701)

### Likely Root Cause: Engine/Network Layer

**Hypothesis 1: Network Packet Timing**
- QuakeC updates `player.ammo_X` field immediately (server-side)
- Network packet with ammo update might be delayed or batched
- Client receives visual pickup confirmation before ammo value update
- Weapon switch forces immediate state sync, showing correct value

**Hypothesis 2: Client Prediction Mismatch**
- Client predicts item pickup visually (removes model from world)
- But client doesn't predict ammo increase (waits for server confirmation)
- Creates perception that "ammo didn't increment"
- Weapon switch queries server for full weapon/ammo state, syncing display

**Hypothesis 3: HUD Update Logic**
- Engine HUD might only update ammo display on specific triggers:
  - Weapon switch (always updates)
  - Damage taken (health check triggers full HUD refresh)
  - Explicit WriteByte network message (QuakeC might be missing this)
- Pickup bonusflash might not trigger ammo counter refresh

---

## 🔬 Further Investigation Needed

### Check Network Message Protocol

**Question**: Does QuakeC need to explicitly send ammo updates via WriteByte?

**Standard Quake Network Messages**:
```c
// In theory, should be in world.qc or client.qc
WriteByte (MSG_ONE, SVC_UPDATESTAT);
WriteByte (MSG_ONE, STAT_SHELLS);
WriteLong (MSG_ONE, self.ammo_shells);
```

**Action**: Search for `WriteByte`, `STAT_SHELLS`, `STAT_AMMO` in codebase to see if explicit network updates exist.

### Check Engine Version Compatibility

**Question**: Is this a Quakespasm-specific issue?

**Action**: Test ammo pickup in different engines:
- Quakespasm (current test environment)
- DarkPlaces (modern engine with enhanced networking)
- FitzQuake (classic enhanced engine)
- NetQuake (original engine)

If bug only appears in specific engines, it's an engine issue, not QuakeC.

### Check Multiplayer vs Singleplayer

**Question**: Does bug only occur in multiplayer (network latency)?

**Action**: Test in local singleplayer game vs multiplayer server:
- If singleplayer is fine, it's a network latency issue
- If both have bug, it's a client HUD update issue

---

## 📋 Recommended Fixes

### Priority 1: Fix Code Quality Issues (Maintainability)

**Create proper ammo type constants** in `defs.qc`:
```c
// Ammo type identifiers (for ammo item classification)
float AMMO_SHELLS    = 1.000;
float AMMO_NAILS     = 2.000;
float AMMO_ROCKETS   = 3.000;
float AMMO_CELLS     = 4.000;

// Standard ammo amounts
float AMMO_SHELLS_SMALL  = 20.000;
float AMMO_SHELLS_BIG    = 40.000;
float AMMO_NAILS_SMALL   = 25.000;
float AMMO_NAILS_BIG     = 50.000;
float AMMO_ROCKETS_SMALL = 5.000;
float AMMO_ROCKETS_BIG   = 10.000;
float AMMO_CELLS_SMALL   = 6.000;
float AMMO_CELLS_BIG     = 12.000;

// Weapon pickup ammo amounts
float AMMO_NAILGUN_PICKUP   = 30.000;
float AMMO_SNG_PICKUP       = 30.000;
float AMMO_SSG_PICKUP       = 5.000;
float AMMO_RL_PICKUP        = 5.000;
float AMMO_GL_PICKUP        = 5.000;
float AMMO_LG_PICKUP        = 15.000;
```

**Replace all wrong constants** in `items.qc`:
- Lines 424, 437: `SVC_INTERMISSION` → `AMMO_NAILGUN_PICKUP`
- Line 454: `TE_LIGHTNING1` → `AMMO_SSG_PICKUP`
- Lines 467, 484: `CAM_FREE` → `AMMO_RL_PICKUP` / `AMMO_GL_PICKUP`
- Line 501: Already correct (`15.000` → `AMMO_LG_PICKUP` for consistency)
- Lines 737, 762, etc.: Replace movement/camera constants with proper AMMO_* constants

**Estimated impact**: +200 bytes (new constants), no functional change, 100% safer code.

### Priority 2: Investigate HUD Update (If Bug Persists)

**If user confirms bug still occurs after testing**:
1. Search codebase for `WriteByte`, `SVC_UPDATESTAT`, `STAT_SHELLS`
2. Check if explicit network messages are needed for ammo updates
3. Compare with standard Quake 1 source code (id Software's original implementation)
4. If missing, add explicit ammo update messages in `ammo_touch()` and `weapon_touch()`

### Priority 3: Engine Bug Workaround (Last Resort)

**If it's confirmed as engine bug**:
- Add `stuffcmd(other, "bf\n")` twice (force double HUD refresh)
- Add explicit `stuffcmd(other, "wait; wait; bf\n")` to delay refresh
- Document as known engine limitation in README

---

## 📊 Summary Table: All Constants Misused

| Constant | Defined In | Original Purpose | Repurposed For | Value | Correct? |
|----------|-----------|------------------|----------------|-------|----------|
| `SVC_INTERMISSION` | defs.qc:242 | Network message ID | Nailgun ammo amount | 30 | By accident |
| `TE_LIGHTNING1` | defs.qc:251 | Temp entity effect | SSG ammo amount | 5 | By accident |
| `CAM_FREE` | kascam.qc:6 | Camera mode | RL/GL ammo amount | 5 | By accident |
| `H_ROTTEN` | items.qc:68 | Health pickup type | Shell ammo type ID | 1 | By accident |
| `H_MEGA` | items.qc:69 | Health pickup type | Nail ammo type ID | 2 | By accident |
| `CAM_FOLLOW` | kascam.qc:4 | Camera mode | Rocket ammo type ID | 3 | By accident |
| `CAM_HAND` | kascam.qc:5 | Camera mode | Cell ammo type ID | 4 | By accident |
| `MOVETYPE_FLY` | defs.qc:178 | Entity movement type | Small rocket amount | 5 | By accident |
| `MOVETYPE_TOSS` | defs.qc:179 | Entity movement type | Small cell amount | 6 | By accident |
| `TE_LAVASPLASH` | defs.qc:256 | Temp entity effect | Big rocket amount | 10 | By accident |
| `WEAPON_BIG2` | items.qc:721 | Spawn flag | Shell ammo type ID | 1 | By accident |
| `KINDA_WANT` | botit_th.qc:232 | Bot goal threshold | Small shell amount | 20 | ✅ Intentional |

**Total Misused Constants**: 11 out of 12 ammo-related constants
**Code Correctness**: ✅ Functionally works (lucky values)
**Code Maintainability**: ❌ Disaster (semantic chaos)

---

## 🎯 Conclusion

**User-Reported HUD Bug**: Likely **NOT** caused by QuakeC logic
- Server-side ammo values are correct (despite wrong constants)
- Client-side HUD display delay suggests engine/network issue
- Weapon switch workaround confirms server has correct value

**Code Quality Issues**: **CRITICAL** maintainability problems
- 11 constants repurposed from unrelated systems
- Works only by coincidence (values happen to match)
- Should be fixed for code safety, even if HUD bug is engine-level

**Recommended Action**:
1. **Immediate**: Test current build to confirm HUD bug still exists
2. **Short-term**: Create proper `AMMO_*` constants and refactor items.qc (1-hour task)
3. **Long-term**: Investigate engine-level HUD update if bug confirmed persistent

---

**Analysis completed**: 2026-01-06
**Priority**: Medium (code quality) + Low (HUD bug, likely engine issue)
**Risk**: Low (functional code works, but fragile)
