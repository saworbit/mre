#!/usr/bin/env python3
"""
Bot Decision Log Analyzer for Modern Reaper Enhancements (MRE)

Analyzes qconsole.log debug output to extract bot behavior patterns,
calculate performance metrics, and suggest tuning improvements.

Usage:
    python analyze_bot_logs.py <path_to_qconsole.log>
    python analyze_bot_logs.py c:\\reaperai\\launch\\quake-spasm\\qconsole.log
"""

import re
import sys
from collections import defaultdict, Counter
from pathlib import Path
from datetime import datetime


class BotLogAnalyzer:
    def __init__(self, log_path):
        self.log_path = Path(log_path)
        self.bots = defaultdict(lambda: {
            'targets': [],
            'goals': [],
            'deaths': 0,
            'kills': 0,
            'target_switches': 0,
            'goal_switches': 0,
            'engagement_time': 0,
            'idle_time': 0,
            'first_timestamp': None,
            'last_timestamp': None,
            'weapon_switches': [],  # NEW: Weapon switch events
            'hear_events': [],      # NEW: Hearing activations
            'combo_events': [],     # NEW: Juggler combos
            'stuck_events': [],     # NEW: Stuck detections
            'unstuck_events': []    # NEW: Unstuck methods
        })

        # Track overall match timing
        self.first_decision_time = None
        self.last_decision_time = None
        self.match_duration_seconds = 0

        # Regex patterns for log parsing
        self.target_pattern = re.compile(r'\[(.+?)\] TARGET: (.+)')
        self.goal_pattern = re.compile(r'\[(.+?)\] GOAL: (.+)')
        self.death_pattern = re.compile(r'(.+?) died')
        self.kill_pattern = re.compile(r'(.+?) was killed by (.+)')

        # NEW: Phase 1 enhanced logging patterns
        self.weapon_pattern = re.compile(r'\[(.+?)\] WEAPON: (.+)')
        self.hear_pattern = re.compile(r'\[(.+?)\] HEAR: (.+)')
        self.combo_pattern = re.compile(r'\[(.+?)\] COMBO: (.+)')
        self.stuck_pattern = re.compile(r'\[(.+?)\] STUCK: (.+)')
        self.unstuck_pattern = re.compile(r'\[(.+?)\] UNSTUCK: (.+)')

        # Timestamp pattern (if present in logs)
        # Quake logs don't have timestamps by default, so we'll estimate from decision count
        self.estimated_duration = True

    def parse_log(self):
        """Parse qconsole.log and extract bot decision data"""
        print(f"[*] Parsing log file: {self.log_path}")

        if not self.log_path.exists():
            print(f"[ERROR] Log file not found: {self.log_path}")
            sys.exit(1)

        with open(self.log_path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                line = line.strip()

                # Parse target selections
                target_match = self.target_pattern.search(line)
                if target_match:
                    bot_name = target_match.group(1)
                    target_info = target_match.group(2)
                    self.bots[bot_name]['targets'].append(target_info)

                    # Count switches (when target changes)
                    if len(self.bots[bot_name]['targets']) > 1:
                        prev_target = self.bots[bot_name]['targets'][-2]
                        if prev_target != target_info:
                            self.bots[bot_name]['target_switches'] += 1

                    # Track engagement vs idle time
                    if target_info == "None visible":
                        self.bots[bot_name]['idle_time'] += 1
                    else:
                        self.bots[bot_name]['engagement_time'] += 1

                # Parse goal selections
                goal_match = self.goal_pattern.search(line)
                if goal_match:
                    bot_name = goal_match.group(1)
                    goal_info = goal_match.group(2)
                    self.bots[bot_name]['goals'].append(goal_info)

                    # Count goal switches
                    if len(self.bots[bot_name]['goals']) > 1:
                        prev_goal = self.bots[bot_name]['goals'][-2]
                        if prev_goal != goal_info:
                            self.bots[bot_name]['goal_switches'] += 1

                # Parse deaths
                death_match = self.death_pattern.search(line)
                if death_match:
                    bot_name = death_match.group(1)
                    if bot_name in self.bots:
                        self.bots[bot_name]['deaths'] += 1

                # Parse weapon switches (NEW)
                weapon_match = self.weapon_pattern.search(line)
                if weapon_match:
                    bot_name = weapon_match.group(1)
                    weapon_info = weapon_match.group(2)
                    self.bots[bot_name]['weapon_switches'].append(weapon_info)

                # Parse hearing events (NEW)
                hear_match = self.hear_pattern.search(line)
                if hear_match:
                    bot_name = hear_match.group(1)
                    hear_info = hear_match.group(2)
                    self.bots[bot_name]['hear_events'].append(hear_info)

                # Parse combo events (NEW)
                combo_match = self.combo_pattern.search(line)
                if combo_match:
                    bot_name = combo_match.group(1)
                    combo_info = combo_match.group(2)
                    self.bots[bot_name]['combo_events'].append(combo_info)

                # Parse stuck events (NEW)
                stuck_match = self.stuck_pattern.search(line)
                if stuck_match:
                    bot_name = stuck_match.group(1)
                    stuck_info = stuck_match.group(2)
                    self.bots[bot_name]['stuck_events'].append(stuck_info)

                # Parse unstuck events (NEW)
                unstuck_match = self.unstuck_pattern.search(line)
                if unstuck_match:
                    bot_name = unstuck_match.group(1)
                    unstuck_info = unstuck_match.group(2)
                    self.bots[bot_name]['unstuck_events'].append(unstuck_info)

        print(f"[OK] Parsed data for {len(self.bots)} bots\n")

    def calculate_statistics(self):
        """Calculate aggregate statistics across all bots"""
        total_decisions = sum(len(bot['targets']) + len(bot['goals']) for bot in self.bots.values())
        total_engagement = sum(bot['engagement_time'] for bot in self.bots.values())
        total_idle = sum(bot['idle_time'] for bot in self.bots.values())
        total_switches = sum(bot['target_switches'] for bot in self.bots.values())

        engagement_pct = (total_engagement / (total_engagement + total_idle) * 100) if (total_engagement + total_idle) > 0 else 0

        # Estimate match duration from decision count
        # Change-only logging with scan_time=1.5s means ~0.4 decisions/second average
        # (bots log on target/goal changes, not every scan)
        if total_decisions > 0:
            # Conservative estimate: assume average 2 decisions per second during active play
            self.match_duration_seconds = total_decisions / 2.0

        # Calculate time-normalized metrics
        switches_per_minute = 0
        switches_per_second = 0
        if self.match_duration_seconds > 0:
            switches_per_minute = (total_switches / self.match_duration_seconds) * 60
            switches_per_second = total_switches / self.match_duration_seconds

        avg_switches_per_bot = total_switches / len(self.bots) if self.bots else 0

        # Calculate per-bot switching rate
        avg_switches_per_bot_per_min = 0
        if self.match_duration_seconds > 0 and len(self.bots) > 0:
            avg_switches_per_bot_per_min = (avg_switches_per_bot / self.match_duration_seconds) * 60

        return {
            'total_decisions': total_decisions,
            'engagement_pct': engagement_pct,
            'total_switches': total_switches,
            'avg_switches_per_bot': avg_switches_per_bot,
            'match_duration_seconds': self.match_duration_seconds,
            'match_duration_minutes': self.match_duration_seconds / 60,
            'switches_per_minute': switches_per_minute,
            'switches_per_second': switches_per_second,
            'avg_switches_per_bot_per_min': avg_switches_per_bot_per_min
        }

    def print_summary(self):
        """Print analysis summary"""
        print("=" * 70)
        print("BOT DECISION LOG ANALYSIS - Modern Reaper Enhancements")
        print("=" * 70)

        stats = self.calculate_statistics()

        print(f"\nOVERALL STATISTICS:")
        print(f"  Total decision events: {stats['total_decisions']}")
        print(f"  Estimated match duration: {stats['match_duration_minutes']:.1f} minutes ({stats['match_duration_seconds']:.0f}s)")
        print(f"  Combat engagement rate: {stats['engagement_pct']:.1f}%")
        print(f"")
        print(f"  Total target switches: {stats['total_switches']}")
        print(f"  Avg switches per bot: {stats['avg_switches_per_bot']:.1f}")
        print(f"")
        print(f"  TIME-NORMALIZED METRICS:")
        print(f"    Switches per minute (all bots): {stats['switches_per_minute']:.1f}")
        print(f"    Switches per second (all bots): {stats['switches_per_second']:.2f}")
        print(f"    Switches per bot per minute: {stats['avg_switches_per_bot_per_min']:.1f}")
        print(f"    Switches per bot per second: {stats['avg_switches_per_bot_per_min']/60:.2f}")

        print(f"\nBOT-SPECIFIC ANALYSIS:")
        print(f"{'Bot Name':<15} {'Targets':<10} {'Goals':<10} {'Switches':<10} {'Engage%':<10}")
        print("-" * 70)

        for bot_name, data in sorted(self.bots.items()):
            total_time = data['engagement_time'] + data['idle_time']
            engage_pct = (data['engagement_time'] / total_time * 100) if total_time > 0 else 0

            print(f"{bot_name:<15} {len(data['targets']):<10} {len(data['goals']):<10} "
                  f"{data['target_switches']:<10} {engage_pct:<10.1f}")

        self.analyze_target_patterns()
        self.analyze_goal_patterns()
        self.analyze_tactical_events()  # NEW: Phase 1 event analysis
        self.suggest_improvements()

    def analyze_target_patterns(self):
        """Analyze target selection patterns"""
        print(f"\nTARGET SELECTION PATTERNS:")

        all_targets = []
        for bot_data in self.bots.values():
            all_targets.extend(bot_data['targets'])

        if not all_targets:
            print("  No target data found.")
            return

        # Count "None visible" frequency
        none_visible_count = sum(1 for t in all_targets if "None visible" in t)
        combat_count = len(all_targets) - none_visible_count

        print(f"  Combat engagements: {combat_count} ({combat_count/len(all_targets)*100:.1f}%)")
        print(f"  Idle/searching: {none_visible_count} ({none_visible_count/len(all_targets)*100:.1f}%)")

        # Extract target scores
        scores = []
        for target in all_targets:
            score_match = re.search(r'score=([\d.]+)', target)
            if score_match:
                scores.append(float(score_match.group(1)))

        if scores:
            avg_score = sum(scores) / len(scores)
            max_score = max(scores)
            min_score = min(scores)
            print(f"  Target scores: avg={avg_score:.1f}, max={max_score:.1f}, min={min_score:.1f}")

    def analyze_goal_patterns(self):
        """Analyze goal selection patterns"""
        print(f"\nGOAL SELECTION PATTERNS:")

        all_goals = []
        for bot_data in self.bots.values():
            all_goals.extend(bot_data['goals'])

        if not all_goals:
            print("  No goal data found.")
            return

        # Count goal types
        goal_types = Counter()
        for goal in all_goals:
            # Extract goal classname (e.g., "item_armor2")
            classname_match = re.match(r'([^\s(]+)', goal)
            if classname_match:
                goal_types[classname_match.group(1)] += 1

        print(f"  Most sought goals:")
        for goal_type, count in goal_types.most_common(5):
            print(f"    {goal_type}: {count} times ({count/len(all_goals)*100:.1f}%)")

    def analyze_tactical_events(self):
        """Analyze Phase 1 enhanced logging events (weapon switches, combos, hearing, stuck)"""
        print(f"\nTACTICAL EVENTS ANALYSIS:")

        # Aggregate counts across all bots
        total_weapon_switches = sum(len(bot['weapon_switches']) for bot in self.bots.values())
        total_hear_events = sum(len(bot['hear_events']) for bot in self.bots.values())
        total_combo_events = sum(len(bot['combo_events']) for bot in self.bots.values())
        total_stuck_events = sum(len(bot['stuck_events']) for bot in self.bots.values())
        total_unstuck_events = sum(len(bot['unstuck_events']) for bot in self.bots.values())

        # Overall summary
        print(f"  Weapon switches (tactical): {total_weapon_switches}")
        print(f"  Simulated Perception (hearing) activations: {total_hear_events}")
        print(f"  Juggler combos executed: {total_combo_events}")
        print(f"  Stuck detections: {total_stuck_events}")
        print(f"  Unstuck methods used: {total_unstuck_events}")

        # Per-bot breakdown (only if events exist)
        if total_weapon_switches > 0 or total_combo_events > 0 or total_stuck_events > 0:
            print(f"\n  PER-BOT TACTICAL BREAKDOWN:")
            print(f"  {'Bot Name':<15} {'Weapons':<10} {'Combos':<10} {'Hears':<10} {'Stuck':<10}")
            print("  " + "-" * 60)
            for bot_name, data in sorted(self.bots.items()):
                weapon_count = len(data['weapon_switches'])
                combo_count = len(data['combo_events'])
                hear_count = len(data['hear_events'])
                stuck_count = len(data['stuck_events'])
                print(f"  {bot_name:<15} {weapon_count:<10} {combo_count:<10} {hear_count:<10} {stuck_count:<10}")

        # Analyze weapon switch patterns
        if total_weapon_switches > 0:
            print(f"\n  WEAPON SWITCH RATIONALE:")
            all_weapon_switches = []
            for bot_data in self.bots.values():
                all_weapon_switches.extend(bot_data['weapon_switches'])

            # Count switch reasons
            tactical_count = sum(1 for w in all_weapon_switches if 'tactical' in w)
            gl_suicide_prevent_count = sum(1 for w in all_weapon_switches if 'GL-suicide-prevent' in w)

            if tactical_count > 0:
                print(f"    Tactical switches: {tactical_count} ({tactical_count/total_weapon_switches*100:.1f}%)")
            if gl_suicide_prevent_count > 0:
                print(f"    GL suicide prevention: {gl_suicide_prevent_count} ({gl_suicide_prevent_count/total_weapon_switches*100:.1f}%)")

        # Analyze combo patterns
        if total_combo_events > 0:
            print(f"\n  JUGGLER COMBO BREAKDOWN:")
            all_combos = []
            for bot_data in self.bots.values():
                all_combos.extend(bot_data['combo_events'])

            shaft_combos = sum(1 for c in all_combos if 'shaft-combo' in c or 'LG' in c)
            burst_combos = sum(1 for c in all_combos if 'burst-combo' in c or 'SSG' in c)

            print(f"    RL -> LG (shaft-combo): {shaft_combos} ({shaft_combos/total_combo_events*100:.1f}%)")
            print(f"    RL -> SSG (burst-combo): {burst_combos} ({burst_combos/total_combo_events*100:.1f}%)")

        # Analyze unstuck methods
        if total_unstuck_events > 0:
            print(f"\n  UNSTUCK METHODS:")
            all_unstuck = []
            for bot_data in self.bots.values():
                all_unstuck.extend(bot_data['unstuck_events'])

            train_surf = sum(1 for u in all_unstuck if 'Train surf' in u)
            rocket_jump = sum(1 for u in all_unstuck if 'Rocket jump' in u)
            super_jump = sum(1 for u in all_unstuck if 'Super jump' in u)

            if train_surf > 0:
                print(f"    Train surf escape: {train_surf} ({train_surf/total_unstuck_events*100:.1f}%)")
            if rocket_jump > 0:
                print(f"    Rocket jump escape: {rocket_jump} ({rocket_jump/total_unstuck_events*100:.1f}%)")
            if super_jump > 0:
                print(f"    Super jump escape: {super_jump} ({super_jump/total_unstuck_events*100:.1f}%)")

    def suggest_improvements(self):
        """Suggest bot tuning improvements based on patterns"""
        print(f"\nSUGGESTED IMPROVEMENTS:")

        stats = self.calculate_statistics()

        # Check engagement rate
        if stats['engagement_pct'] < 20:
            print(f"  [!] Low engagement rate ({stats['engagement_pct']:.1f}%)")
            print(f"      -> Consider: Increase movement speed, improve vision range")
            print(f"      -> Consider: Add goal bias toward high-traffic areas")

        # Check switch frequency with TIME-AWARE THRESHOLDS
        switches_per_bot_per_min = stats.get('avg_switches_per_bot_per_min', 0)

        # For scan_time = 1.5s (40 scans/minute):
        # - GOOD: ~10-20 switches/min per bot (25-50% of scans find new target)
        # - EXCESSIVE: >30 switches/min per bot (75%+ of scans switch - indicates flip-flopping)
        # - TOO LOW: <5 switches/min per bot (<12% of scans switch - too sticky)

        if switches_per_bot_per_min > 30:
            print(f"  [!] EXCESSIVE target switching ({switches_per_bot_per_min:.1f} per bot per minute)")
            print(f"      With scan_time=1.5s, bots scan 40 times/min")
            print(f"      Current: {switches_per_bot_per_min/40*100:.1f}% of scans switch targets (too high!)")
            print(f"      -> Consider: Increase target commitment time (scan_time 1.5s → 2.0s)")
            print(f"      -> Consider: Add stronger hysteresis to target scoring")
            print(f"      -> Target: 10-20 switches/min per bot (25-50% switch rate)")
        elif switches_per_bot_per_min > 20:
            print(f"  [~] MODERATE-HIGH target switching ({switches_per_bot_per_min:.1f} per bot per minute)")
            print(f"      With scan_time=1.5s, bots scan 40 times/min")
            print(f"      Current: {switches_per_bot_per_min/40*100:.1f}% of scans switch targets")
            print(f"      This may be acceptable for FFA with multi-opponent awareness")
            print(f"      -> If bots seem distracted: Increase scan_time to 2.0s")
            print(f"      -> If combat effectiveness is good: Current rate is acceptable")
        elif switches_per_bot_per_min < 5:
            print(f"  [!] LOW target switching ({switches_per_bot_per_min:.1f} per bot per minute)")
            print(f"      Bots may be too committed to targets (missing better opportunities)")
            print(f"      -> Consider: Decrease scan_time interval (1.5s → 1.0s)")
            print(f"      -> Consider: Lower thresholds for better target selection")
        else:
            print(f"  [OK] GOOD target switching rate ({switches_per_bot_per_min:.1f} per bot per minute)")
            print(f"      With scan_time=1.5s, {switches_per_bot_per_min/40*100:.1f}% of scans find new target")
            print(f"      This is healthy for FFA dynamics!")

        # Check goal diversity
        all_goals = []
        for bot_data in self.bots.values():
            all_goals.extend(bot_data['goals'])

        unique_goals = len(set(all_goals))
        if unique_goals < 5:
            print(f"  [!] Low goal diversity ({unique_goals} unique goals)")
            print(f"      -> Consider: Increase weight for underutilized items")
            print(f"      -> Consider: Add randomization to goal scoring")

        print(f"\n[*] Analysis complete! Use these insights to tune bot behavior.")


def main():
    if len(sys.argv) < 2:
        print("Usage: python analyze_bot_logs.py <path_to_qconsole.log>")
        print("Example: python analyze_bot_logs.py c:\\reaperai\\launch\\quake-spasm\\qconsole.log")
        sys.exit(1)

    log_path = sys.argv[1]
    analyzer = BotLogAnalyzer(log_path)
    analyzer.parse_log()
    analyzer.print_summary()


if __name__ == "__main__":
    main()
