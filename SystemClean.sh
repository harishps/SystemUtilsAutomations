#!/bin/bash

echo "🔍 Dry Run: Listing cache folders to be cleared..."

# ====== BROWSER CACHES ======
chrome_cache=(
  "$HOME/Library/Caches/Google/Chrome"
)
# Cache only — do not include History.db, Bookmarks, or Downloads
safari_cache=(
  "$HOME/Library/Caches/com.apple.Safari"
  "$HOME/Library/Caches/com.apple.WebKit.Networking"
  "$HOME/Library/Caches/com.apple.WebKit.GPU"
  "$HOME/Library/Safari/Favicon Cache"
  "$HOME/Library/Containers/com.apple.Safari/Data/Library/Caches"
)
firefox_cache=()
for profile in "$HOME/Library/Caches/Firefox/Profiles/"*.default-release; do
  [ -d "$profile" ] && firefox_cache+=("$profile/cache2")
done
edge_cache=(
  "$HOME/Library/Caches/Microsoft Edge"
)
brave_cache=(
  "$HOME/Library/Caches/BraveSoftware"
)

# ====== SYSTEM & USER CACHES ======
system_cache=(
  "/Library/Caches"
)
# Shown for size only — deletion disabled by default (see risks in script header)
user_cache=(
  "$HOME/Library/Caches"
  "$HOME/Library/Logs"
)

# ====== APP CACHES ======
slack_cache=(
  "$HOME/Library/Application Support/Slack/Service Worker/CacheStorage"
)
teams_cache=(
  "$HOME/Library/Application Support/Microsoft/Teams/Cache"
)
zoom_cache=(
  "$HOME/Library/Application Support/zoom.us/data"
)

# ====== HELPERS ======
CLEAR_OK=0
CLEAR_FAIL=0
CLEAR_SKIP=0
SAFARI_FAIL=0

calc_size() {
  local folder=$1
  if [ -e "$folder" ]; then
    if size=$(du -sh "$folder" 2>/dev/null); then
      echo "$size"
    else
      echo "$folder (size unavailable — may need Full Disk Access)"
    fi
  else
    echo "$folder (not found)"
  fi
}

safari_is_protected() {
  local probe="$HOME/Library/Caches/com.apple.Safari"
  [ -e "$probe" ] || return 1
  ls "$probe" &>/dev/null
}

print_safari_help() {
  echo ""
  echo "Safari caches are protected by macOS (TCC). To clear them:"
  echo "  1. Quit Safari completely."
  echo "  2. System Settings → Privacy & Security → Full Disk Access"
  echo "     → enable the app running this script (Terminal, iTerm, or Cursor)."
  echo "  3. Re-run this script."
  echo ""
  echo "Or without Full Disk Access:"
  echo "  Safari → Settings → Privacy → Manage Website Data → Remove All"
}

clear_path() {
  local path=$1
  local is_safari=$2

  if [ ! -e "$path" ]; then
    CLEAR_SKIP=$((CLEAR_SKIP + 1))
    return 0
  fi

  if rm -rf "$path" 2>/dev/null; then
    echo "  ✓ $path"
    CLEAR_OK=$((CLEAR_OK + 1))
    return 0
  fi

  echo "  ✗ $path"
  CLEAR_FAIL=$((CLEAR_FAIL + 1))
  if [ "$is_safari" = "1" ]; then
    SAFARI_FAIL=1
  fi
  return 1
}

clear_paths() {
  local is_safari=$1
  shift
  local path
  for path in "$@"; do
    clear_path "$path" "$is_safari" || true
  done
}

# ====== SHOW SIZES BEFORE CLEANUP ======
echo ""
echo "Google Chrome:"; for path in "${chrome_cache[@]}"; do calc_size "$path"; done
echo ""
echo "Safari:"; for path in "${safari_cache[@]}"; do calc_size "$path"; done
echo ""
echo "Firefox:"
if [ ${#firefox_cache[@]} -eq 0 ]; then
  echo "$HOME/Library/Caches/Firefox/Profiles/*.default-release/cache2 (not found)"
else
  for path in "${firefox_cache[@]}"; do calc_size "$path"; done
fi
echo ""
echo "Edge:"; for path in "${edge_cache[@]}"; do calc_size "$path"; done
echo ""
echo "Brave:"; for path in "${brave_cache[@]}"; do calc_size "$path"; done
echo ""
echo "System Cache:"; for path in "${system_cache[@]}"; do calc_size "$path"; done
echo ""
echo "User Cache (report only — not deleted unless you uncomment rm below):"
for path in "${user_cache[@]}"; do calc_size "$path"; done
echo ""
echo "Slack:"; for path in "${slack_cache[@]}"; do calc_size "$path"; done
echo ""
echo "Teams:"; for path in "${teams_cache[@]}"; do calc_size "$path"; done
echo ""
echo "Zoom:"; for path in "${zoom_cache[@]}"; do calc_size "$path"; done

if safari_is_protected; then
  echo ""
  echo "⚠️  Safari cache is protected by macOS. Other caches can still be cleared;"
  echo "   Safari needs Full Disk Access for this script, or clear it manually in Safari."
fi

# ====== CONFIRMATION ======
echo ""
read -p "❓ Proceed with deleting these caches? (Y/N): " choice

if [[ "$choice" == "Y" || "$choice" == "y" ]]; then
  echo "🧹 Clearing caches (quit browsers first)..."
  echo ""

  echo "Google Chrome:"
  clear_paths 0 "${chrome_cache[@]}"
  echo ""
  echo "Safari:"
  clear_paths 1 "${safari_cache[@]}"
  echo ""
  echo "Firefox:"
  clear_paths 0 "${firefox_cache[@]}"
  echo ""
  echo "Edge:"
  clear_paths 0 "${edge_cache[@]}"
  echo ""
  echo "Brave:"
  clear_paths 0 "${brave_cache[@]}"
  # clear_paths 0 "${system_cache[@]}"
  # clear_paths 0 "${user_cache[@]}"
  echo ""
  echo "Slack:"
  clear_paths 0 "${slack_cache[@]}"
  echo ""
  echo "Teams:"
  clear_paths 0 "${teams_cache[@]}"
  # echo "Zoom:"; clear_paths 0 "${zoom_cache[@]}"

  echo ""
  if [ "$CLEAR_FAIL" -gt 0 ]; then
    echo "⚠️  Finished with errors: $CLEAR_OK cleared, $CLEAR_FAIL failed, $CLEAR_SKIP skipped (not found)."
    [ "$SAFARI_FAIL" -eq 1 ] && print_safari_help
  else
    echo "✅ Caches cleared: $CLEAR_OK removed, $CLEAR_SKIP not found."
  fi
else
  echo "❌ Aborted. No files deleted."
fi