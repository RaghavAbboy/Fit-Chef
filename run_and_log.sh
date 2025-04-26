#!/bin/bash
# Usage: ./run_and_log.sh <your command here>
# Example: ./run_and_log.sh ls -la

LOG_FILE="last_command_output.txt"

# Run the command, log output (stdout and stderr), and print it to the terminal
"$@" > "$LOG_FILE" 2>&1
cat "$LOG_FILE" 