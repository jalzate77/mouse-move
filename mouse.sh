#!/bin/bash

# MOUSE AUTOMATION SCRIPT WITH ENHANCEMENTS

# Step 0: Configurable Options
VERBOSE=true     # Set to false to mute logging
DRY_RUN=false    # Set to true for test mode (no actual input)
RUN_DURATION=0   # Duration in seconds (0 = run forever)

# Step 1: Install dependencies (Fedora)
if ! command -v xdotool &>/dev/null || ! command -v slop &>/dev/null; then
  echo "[INFO] Installing required packages..."
  sudo dnf install -y xdotool slop
fi

# Step 2: Prompt user to select screen area
echo "[INFO] Select screen area to confine mouse movement..."
read -r GEOM < <(slop -f "%x %y %w %h")
IFS=' ' read -r START_X START_Y WIDTH HEIGHT <<< "$GEOM"
END_X=$((START_X + WIDTH))
END_Y=$((START_Y + HEIGHT))
echo "[INFO] Mouse will operate in: X=$START_X-$END_X, Y=$START_Y-$END_Y"

# Step 3: Logging and dry-run wrappers
log() {
  $VERBOSE && echo -e "$@"
}

if $DRY_RUN; then
  xdotool() {
    log "[DRYRUN] xdotool $*"
  }
fi

# Step 4: Trap for graceful exit
trap 'echo -e "\n[INFO] Exiting..."; exit 0' SIGINT

# Step 5: Mouse movement function
move_mouse() {
  local x=$((RANDOM % WIDTH + START_X))
  local y=$((RANDOM % HEIGHT + START_Y))
  log "[MOUSE] Moving to ($x, $y)"
  xdotool mousemove "$x" "$y"
}

# Step 6: Random action function with no repetition
LAST_ACTION=""
random_action() {
  local action=$((RANDOM % 15))
  while [[ "$action" == "$LAST_ACTION" ]]; do
    action=$((RANDOM % 15))
  done
  LAST_ACTION=$action

  case $action in
    0)
      log "[ACTION] Alt+Tab"
      xdotool keydown Alt key Tab keyup Alt
      ;;
    1)
      log "[ACTION] Ctrl+Tab"
      xdotool keydown Ctrl key Tab keyup Ctrl
      ;;
    2)
      log "[ACTION] Ctrl+Page_Up"
      xdotool keydown Ctrl key Page_Up keyup Ctrl
      ;;
    3|4)
      log "[ACTION] Ctrl+Page_Down"
      xdotool keydown Ctrl key Page_Down keyup Ctrl
      ;;
    5)
      log "[ACTION] Page_Up"
      xdotool key Page_Up
      ;;
    6)
      log "[ACTION] Page_Down"
      xdotool key Page_Down
      ;;
    7)
      log "[ACTION] Home"
      xdotool key Home
      ;;
    8)
      log "[ACTION] End"
      xdotool key End
      ;;
    9)
      log "[ACTION] Escape"
      xdotool key Escape
      ;;
    10|11)
      log "[ACTION] Scroll Wheel"
      amount=$((RANDOM % 5 + 1))
      direction=$((RANDOM % 2))
      if [ "$direction" -eq 0 ]; then
        xdotool click --repeat "$amount" --delay 100 4  # Scroll Up
      else
        xdotool click --repeat "$amount" --delay 100 5  # Scroll Down
      fi
      ;;
    12)
      log "[ACTION] Mouse Click"
      xdotool click $((RANDOM % 3 + 1))  # 1=left, 2=middle, 3=right
      ;;
    *)
      log "[ACTION] Idle (no key)"
      ;;
  esac
}

# Step 7: Interval sets and shuffling
INTERVAL_SETS=(
  "1 3"
  "1 2"
)

shuffle_intervals() {
  local i tmp size rand
  size=${#INTERVAL_SETS[@]}
  for ((i = size - 1; i > 0; i--)); do
    rand=$((RANDOM % (i + 1)))
    tmp=${INTERVAL_SETS[i]}
    INTERVAL_SETS[i]=${INTERVAL_SETS[rand]}
    INTERVAL_SETS[rand]=$tmp
  done
}
shuffle_intervals

# Step 8: Main loop
START_TIME=$(date +%s)
LAST_INTERVAL_SWITCH=$START_TIME
INTERVAL_INDEX=0
NEXT_ACTION_TIME=$((RANDOM % 5 + 2))

while true; do
  # Skip actions between 3AM and 9PM
  HOUR=$(date +%H)
  log "[INFO] Current hour is $HOUR"
  if (( HOUR < 20 && HOUR > 4 )); then
    sleep 60
    continue
  fi

  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - START_TIME))

  # Stop if run duration is set
  if (( RUN_DURATION > 0 && ELAPSED >= RUN_DURATION )); then
    log "[INFO] Run time of $RUN_DURATION seconds reached. Exiting..."
    break
  fi

  # Change interval set every 10 minutes
  if (( CURRENT_TIME - LAST_INTERVAL_SWITCH >= 600 )); then
    INTERVAL_INDEX=$(((INTERVAL_INDEX + 1) % ${#INTERVAL_SETS[@]}))
    LAST_INTERVAL_SWITCH=$CURRENT_TIME
    log "[INFO] Switched to interval set #$((INTERVAL_INDEX + 1)): ${INTERVAL_SETS[INTERVAL_INDEX]}"
  fi

  # Get min and max from current interval set
  IFS=' ' read -r MIN_INTERVAL MAX_INTERVAL <<< "${INTERVAL_SETS[$INTERVAL_INDEX]}"
  SLEEP_INTERVAL=$((RANDOM % (MAX_INTERVAL - MIN_INTERVAL + 1) + MIN_INTERVAL))

  move_mouse

  # Trigger random action if it's time
  if (( NEXT_ACTION_TIME <= 0 )); then
    random_action
    NEXT_ACTION_TIME=$((RANDOM % 5 + 2))
  else
    NEXT_ACTION_TIME=$((NEXT_ACTION_TIME - SLEEP_INTERVAL))
  fi

  sleep "$SLEEP_INTERVAL"
done

