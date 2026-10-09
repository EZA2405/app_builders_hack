#!/bin/zsh
# Dump menus of training apps. Launches apps in background if needed; quits only the ones it launched.
OUT=${1:-/tmp/sg/train}; mkdir -p $OUT
APP="${0:A:h}/../app/build/ScreenGuide.app"
APPS=("TextEdit" "Notes" "Calendar" "Reminders" "Photos" "Music" "Maps" "Calculator" "QuickTime Player" "Books" "Freeform" "Contacts" "Font Book" "Activity Monitor" "Disk Utility" "Terminal" "Stickies" "Numbers" "VLC" "Spotify" "Audacity" "Zed")
for a in $APPS; do
  f="$OUT/$(echo $a | tr -d ' ' | tr A-Z a-z).json"
  launched=0
  if ! pgrep -xq "$a" && ! osascript -e "application \"$a\" is running" 2>/dev/null | grep -q true; then
    open -g -a "$a" 2>/dev/null || { echo "skip $a (not installed)"; continue; }
    launched=1; sleep 6
  fi
  open -W -n $APP --args --dump "$a" "$f" --menus-only
  n=$(python3 -c "import json;d=json.load(open('$f'));print(d.get('error') or len(d['commands']))" 2>/dev/null)
  echo "$a: $n (launched=$launched)"
  [ $launched = 1 ] && osascript -e "tell application \"$a\" to quit" 2>/dev/null
done
