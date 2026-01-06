// ===== DM2 ROCKET JUMP WAYPOINTS =====
// Generated: 2 validated RJ techniques from player observation
// Source: Player observation mode (impulse 199)
// Format: SpawnLearnedRJ(origin, angles, velocity_gain, technique_type)
//
// PLAYER OBSERVATION LEARNING SYSTEM - Phase 1: Rocket Jump Detection

void() LoadPlayerLearnedRJ_dm2 =
{
    // RJ #1: vel_gain=234.8 u/s, height~23u
    SpawnLearnedRJ('1969.5 -481.6 114.9', '-29.5 -111.7 0.3', 234.8, "rj_vertical");

    // RJ #2: vel_gain=214.0 u/s, height~21u
    SpawnLearnedRJ('1765.4 -529.4 40.6', '-29.5 -50.3 -2.1', 214.0, "rj_vertical");
};
