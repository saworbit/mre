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
            'idle_time': 0
        })

        # Regex patterns for log parsing
        self.target_pattern = re.compile(r'\[(.+?)\] TARGET: (.+)')
        self.goal_pattern = re.compile(r'\[(.+?)\] GOAL: (.+)')
        self.death_pattern = re.compile(r'(.+?) died')
        self.kill_pattern = re.compile(r'(.+?) was killed by (.+)')

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

        print(f"[OK] Parsed data for {len(self.bots)} bots\n")

    def calculate_statistics(self):
        """Calculate aggregate statistics across all bots"""
        total_decisions = sum(len(bot['targets']) + len(bot['goals']) for bot in self.bots.values())
        total_engagement = sum(bot['engagement_time'] for bot in self.bots.values())
        total_idle = sum(bot['idle_time'] for bot in self.bots.values())
        total_switches = sum(bot['target_switches'] for bot in self.bots.values())

        engagement_pct = (total_engagement / (total_engagement + total_idle) * 100) if (total_engagement + total_idle) > 0 else 0

        return {
            'total_decisions': total_decisions,
            'engagement_pct': engagement_pct,
            'total_switches': total_switches,
            'avg_switches_per_bot': total_switches / len(self.bots) if self.bots else 0
        }

    def print_summary(self):
        """Print analysis summary"""
        print("=" * 70)
        print("BOT DECISION LOG ANALYSIS - Modern Reaper Enhancements")
        print("=" * 70)

        stats = self.calculate_statistics()

        print(f"\nOVERALL STATISTICS:")
        print(f"  Total decision events: {stats['total_decisions']}")
        print(f"  Combat engagement rate: {stats['engagement_pct']:.1f}%")
        print(f"  Total target switches: {stats['total_switches']}")
        print(f"  Avg switches per bot: {stats['avg_switches_per_bot']:.1f}")

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

    def suggest_improvements(self):
        """Suggest bot tuning improvements based on patterns"""
        print(f"\nSUGGESTED IMPROVEMENTS:")

        stats = self.calculate_statistics()

        # Check engagement rate
        if stats['engagement_pct'] < 20:
            print(f"  [!] Low engagement rate ({stats['engagement_pct']:.1f}%)")
            print(f"      -> Consider: Increase movement speed, improve vision range")
            print(f"      -> Consider: Add goal bias toward high-traffic areas")

        # Check switch frequency
        if stats['avg_switches_per_bot'] > 20:
            print(f"  [!] High target switching ({stats['avg_switches_per_bot']:.1f} per bot)")
            print(f"      -> Consider: Increase target commitment time")
            print(f"      -> Consider: Add hysteresis to target scoring")
        elif stats['avg_switches_per_bot'] < 3:
            print(f"  [!] Low target switching ({stats['avg_switches_per_bot']:.1f} per bot)")
            print(f"      -> Consider: Decrease scan_time interval")
            print(f"      -> Consider: Lower thresholds for better target selection")

        # Check goal diversity
        all_goals = []
        for bot_data in self.bots.values():
            all_goals.extend(bot_data['goals'])

        unique_goals = len(set(all_goals))
        if unique_goals < 5:
            print(f"  [!] Low goal diversity ({unique_goals} unique goals)")
            print(f"      -> Consider: Increase weight for underutilized items")
            print(f"      -> Consider: Add randomization to goal scoring")

        if stats['engagement_pct'] >= 20 and 3 <= stats['avg_switches_per_bot'] <= 20 and unique_goals >= 5:
            print(f"  [OK] Bot behavior looks good! No critical issues detected.")

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
