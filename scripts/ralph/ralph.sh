#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop for job_alrimi
# Usage: ./ralph.sh [--tool claude] [max_iterations]
#
# 이 스크립트는 Claude Code를 반복 실행하여 prd.json의 모든 항목이 완료될 때까지 작업합니다.
# 각 반복은 새로운 컨텍스트로 시작되며, git 히스토리, progress.txt, prd.json을 통해 메모리가 유지됩니다.

set -e

# Parse arguments
TOOL="claude"  # Default to claude
MAX_ITERATIONS=10

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    *)
      # Assume it's max_iterations if it's a number
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

# Validate tool choice
if [[ "$TOOL" != "claude" ]]; then
  echo "Error: Invalid tool '$TOOL'. Currently only 'claude' is supported."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
CLAUDE_PROMPT="$SCRIPT_DIR/CLAUDE.md"

# Check for required files
if [ ! -f "$PRD_FILE" ]; then
  echo "Error: prd.json not found at $PRD_FILE"
  echo "Please create a prd.json file with your user stories."
  echo "See prd.json.example for the expected format."
  exit 1
fi

if [ ! -f "$CLAUDE_PROMPT" ]; then
  echo "Error: CLAUDE.md not found at $CLAUDE_PROMPT"
  exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed."
  echo "Install with: brew install jq"
  exit 1
fi

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "  Archived to: $ARCHIVE_FOLDER"

    # Reset progress file for new run
    echo "# Ralph Progress Log - job_alrimi" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log - job_alrimi" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           Ralph Agent - job_alrimi Project                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Tool: $TOOL"
echo "Max iterations: $MAX_ITERATIONS"
echo "PRD: $PRD_FILE"
echo "Progress: $PROGRESS_FILE"
echo ""

# Count total and completed stories
TOTAL_STORIES=$(jq '.userStories | length' "$PRD_FILE")
COMPLETED_STORIES=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
echo "Stories: $COMPLETED_STORIES / $TOTAL_STORIES completed"
echo ""

cd "$PROJECT_ROOT"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "  Ralph Iteration $i of $MAX_ITERATIONS"
  echo "═══════════════════════════════════════════════════════════════"

  # Run Claude Code with the ralph prompt
  # --dangerously-skip-permissions: 자율 작동을 위한 권한 스킵
  # --print: 출력만 받음
  OUTPUT=$(claude --dangerously-skip-permissions --print < "$CLAUDE_PROMPT" 2>&1 | tee /dev/stderr) || true

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                    All tasks completed!                       ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Completed at iteration $i of $MAX_ITERATIONS"

    # Final status
    COMPLETED_STORIES=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
    echo "Final status: $COMPLETED_STORIES / $TOTAL_STORIES stories completed"
    exit 0
  fi

  # Update progress count
  COMPLETED_STORIES=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
  echo ""
  echo "Iteration $i complete. Progress: $COMPLETED_STORIES / $TOTAL_STORIES stories"
  echo "Continuing in 2 seconds..."
  sleep 2
done

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              Max iterations reached                            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
COMPLETED_STORIES=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
echo "Final status: $COMPLETED_STORIES / $TOTAL_STORIES stories completed"
exit 1
