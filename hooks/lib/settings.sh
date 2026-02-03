#!/usr/bin/env bash
# Settings management for agent-fork-join
#
# Provides functions to check plugin enabled/disabled state.
# Supports both environment variables and persistent settings file.
#
# Priority (highest to lowest):
#   1. FORK_JOIN_DISABLED=1 environment variable
#   2. ~/.config/agent-fork-join/settings.json { "enabled": false }
#   3. Default: enabled

SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/agent-fork-join"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"

# Check if plugin is disabled
# Returns 0 (true) if disabled, 1 (false) if enabled
fork_join_is_disabled() {
	# Priority 1: Environment variable (immediate override)
	if [[ "${FORK_JOIN_DISABLED:-}" == "1" ]]; then
		return 0
	fi

	# Priority 2: Settings file
	if [[ -f "$SETTINGS_FILE" ]]; then
		local enabled
		if command -v jq >/dev/null 2>&1; then
			enabled=$(jq -r '.enabled // true' "$SETTINGS_FILE" 2>/dev/null)
			if [[ "$enabled" == "false" ]]; then
				return 0
			fi
		fi
	fi

	# Default: enabled
	return 1
}

# Check if plugin is enabled (inverse of disabled)
# Returns 0 (true) if enabled, 1 (false) if disabled
fork_join_is_enabled() {
	if fork_join_is_disabled; then
		return 1
	fi
	return 0
}

# Get a setting value from the settings file
# Usage: fork_join_get_setting "key" "default_value"
fork_join_get_setting() {
	local key="$1"
	local default="${2:-}"

	if [[ -f "$SETTINGS_FILE" ]] && command -v jq >/dev/null 2>&1; then
		local value
		value=$(jq -r ".$key // empty" "$SETTINGS_FILE" 2>/dev/null)
		if [[ -n "$value" ]]; then
			echo "$value"
			return 0
		fi
	fi

	echo "$default"
}

# Initialize settings directory and file with defaults
fork_join_init_settings() {
	if [[ ! -d "$SETTINGS_DIR" ]]; then
		mkdir -p "$SETTINGS_DIR"
	fi

	if [[ ! -f "$SETTINGS_FILE" ]]; then
		cat >"$SETTINGS_FILE" <<'EOF'
{
  "enabled": true
}
EOF
	fi
}
