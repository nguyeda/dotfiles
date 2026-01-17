#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
import time
from datetime import datetime


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Ralph - Autonomous Coding Agent",
        usage=(
            "./ralph.py <plan_path> [-m MAX_ITERATIONS] [-s SLEEP_SECONDS] "
            "[-a claude|opencode]"
        ),
    )
    parser.add_argument("plan_path", help="Path to the plan directory")
    parser.add_argument(
        "-m",
        "--max",
        dest="max_iterations",
        type=int,
        default=20,
        help="Maximum iterations (default: 20)",
    )
    parser.add_argument(
        "-s",
        "--sleep",
        dest="sleep_seconds",
        type=int,
        default=2,
        help="Seconds to sleep between iterations (default: 2)",
    )
    parser.add_argument(
        "-a",
        "--agent",
        choices=("claude", "opencode"),
        default="claude",
        help="Agent CLI to call (default: claude)",
    )
    return parser.parse_args()


def timestamp() -> str:
    return datetime.now().strftime("%H:%M:%S")


def main() -> int:
    args = parse_args()

    plan_path = args.plan_path
    max_iterations = args.max_iterations
    sleep_seconds = args.sleep_seconds
    agent_cli = args.agent

    if os.path.isabs(plan_path):
        plan_dir = plan_path
    else:
        plan_dir = os.path.join(os.getcwd(), plan_path)

    plan_name = os.path.basename(plan_path)
    prd_file = os.path.join(plan_dir, "prd.md")
    progress_file = os.path.join(plan_dir, "progress.md")

    if not os.path.isfile(prd_file):
        print(f"Error: PRD file not found at {prd_file}")
        return 1

    os.makedirs(plan_dir, exist_ok=True)
    with open(progress_file, "a", encoding="utf-8"):
        pass

    print("===========================================")
    print("  Ralph - Autonomous Coding Agent")
    print("===========================================")
    print(f"Plan:     {plan_name}")
    print(f"PRD:      {prd_file}")
    print(f"Progress: {progress_file}")
    print(f"Max:      {max_iterations} iterations")
    print(f"Agent:    {agent_cli}")
    print("===========================================")
    print("")

    for iteration in range(1, max_iterations + 1):
        print(
            f"[{timestamp()}] Iteration {iteration} of {max_iterations} - Starting..."
        )
        print(f"[{timestamp()}] Calling {agent_cli}...")

        prompt = (
            "Delegate to the ralph agent with the relevant file paths.\n\n"
            "Include:\n"
            f"- Plan name: {plan_name}\n"
            f"- PRD file: {prd_file}\n"
            f"- Progress file: {progress_file}\n\n"
            "Return the ralph agent response exactly."
        )

        command = ["claude", "--dangerously-skip-permissions", "-p", prompt]
        if agent_cli == "opencode":
            command = ["opencode", "-p", prompt]

        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()

        print(f"[{timestamp()}] {agent_cli} finished")
        print("")
        print("--- Result ---")
        print(result)
        print("--- End Result ---")
        print("")

        if "<promise>COMPLETE</promise>" in result:
            print("===========================================")
            print(f"  All tasks complete after {iteration} iterations!")
            print("===========================================")
            return 0

        print(f"[{timestamp()}] Sleeping {sleep_seconds}s before next iteration...")
        time.sleep(sleep_seconds)

    print("===========================================")
    print(f"  Reached max iterations ({max_iterations})")
    print("===========================================")
    return 1


if __name__ == "__main__":
    sys.exit(main())
