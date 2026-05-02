# shellcheck shell=sh
#
# Source this from ~/.bashrc or ~/.zshrc on remote hosts that you connect to
# via WezTerm SSH / SSHMUX domains. It emits pane-scoped user vars so the local
# status bar can render remote CPU / memory / disk usage.

: "${WEZTERM_REMOTE_METRICS_INTERVAL:=8}"

__wezterm_remote_metrics_has_command() {
  command -v "$1" >/dev/null 2>&1
}

__wezterm_remote_metrics_now() {
  date +%s 2>/dev/null
}

__wezterm_remote_metrics_base64() {
  if ! __wezterm_remote_metrics_has_command base64; then
    return 1
  fi

  if printf 'x' | base64 -w 0 >/dev/null 2>&1; then
    printf '%s' "$1" | base64 -w 0
    return 0
  fi

  printf '%s' "$1" | base64 | tr -d '\r\n'
}

__wezterm_remote_metrics_set_var() {
  name=$1
  value=$2

  if command -v __wezterm_set_user_var >/dev/null 2>&1; then
    __wezterm_set_user_var "$name" "$value"
    return 0
  fi

  encoded=$(__wezterm_remote_metrics_base64 "$value") || return 1

  if [ -n "${TMUX:-}" ]; then
    printf '\033Ptmux;\033\033]1337;SetUserVar=%s=%s\007\033\\' "$name" "$encoded"
  else
    printf '\033]1337;SetUserVar=%s=%s\007' "$name" "$encoded"
  fi
}

__wezterm_remote_metrics_disk_path() {
  if [ -n "${PWD:-}" ] && [ -d "${PWD:-}" ]; then
    printf '%s\n' "$PWD"
    return 0
  fi

  if [ -n "${HOME:-}" ] && [ -d "${HOME:-}" ]; then
    printf '%s\n' "$HOME"
    return 0
  fi

  printf '/\n'
}

__wezterm_remote_metrics_disk() {
  disk_path=$(__wezterm_remote_metrics_disk_path)
  df -P "$disk_path" 2>/dev/null | awk 'NR==2 { gsub("%", "", $5); print $5; exit }'
}

__wezterm_remote_metrics_linux_cpu() {
  sample=$(awk '/^cpu / { idle = $5 + $6; total = 0; for (i = 2; i <= NF; i = i + 1) total += $i; print total "|" idle; exit }' /proc/stat 2>/dev/null)
  if [ -z "$sample" ]; then
    return 0
  fi

  total=${sample%%|*}
  idle=${sample#*|}
  cpu=

  if [ -n "${__WEZTERM_REMOTE_CPU_TOTAL:-}" ] && [ -n "${__WEZTERM_REMOTE_CPU_IDLE:-}" ]; then
    delta_total=$((total - __WEZTERM_REMOTE_CPU_TOTAL))
    delta_idle=$((idle - __WEZTERM_REMOTE_CPU_IDLE))

    if [ "$delta_total" -gt 0 ]; then
      cpu=$(( (100 * (delta_total - delta_idle) + (delta_total / 2)) / delta_total ))
    fi
  fi

  __WEZTERM_REMOTE_CPU_TOTAL=$total
  __WEZTERM_REMOTE_CPU_IDLE=$idle

  printf '%s\n' "$cpu"
}

__wezterm_remote_metrics_linux_mem() {
  awk '
    /^MemTotal:/ { total = $2 }
    /^MemAvailable:/ { available = $2 }
    /^MemFree:/ { free = $2 }
    /^Buffers:/ { buffers = $2 }
    /^Cached:/ { cached = $2 }
    END {
      if (!available) {
        available = free + buffers + cached
      }

      if (total > 0) {
        printf "%d", ((total - available) * 100 / total)
      }
    }
  ' /proc/meminfo 2>/dev/null
}

__wezterm_remote_metrics_macos_cpu() {
  top -l 2 -n 0 2>/dev/null | awk '/CPU usage/ { idle = $(NF - 1) } END { gsub("%", "", idle); if (idle != "") printf "%d", 100 - idle }'
}

__wezterm_remote_metrics_macos_mem() {
  total=$(sysctl -n hw.memsize 2>/dev/null)
  if [ -z "$total" ]; then
    return 0
  fi

  vm_stat 2>/dev/null | awk -v total="$total" '
    /page size of/ { gsub("\\.", "", $8); page = $8 }
    /Pages free/ { gsub("\\.", "", $3); free = $3 }
    /Pages speculative/ { gsub("\\.", "", $3); speculative = $3 }
    END {
      available = (free + speculative) * page
      if (total > 0) {
        printf "%d", ((total - available) * 100 / total)
      }
    }
  '
}

__wezterm_remote_metrics_collect() {
  case "$(uname -s 2>/dev/null)" in
    Linux)
      __WEZTERM_REMOTE_CPU_CACHE=$(__wezterm_remote_metrics_linux_cpu)
      __WEZTERM_REMOTE_MEM_CACHE=$(__wezterm_remote_metrics_linux_mem)
      ;;
    Darwin)
      __WEZTERM_REMOTE_CPU_CACHE=$(__wezterm_remote_metrics_macos_cpu)
      __WEZTERM_REMOTE_MEM_CACHE=$(__wezterm_remote_metrics_macos_mem)
      ;;
    *)
      __WEZTERM_REMOTE_CPU_CACHE=
      __WEZTERM_REMOTE_MEM_CACHE=
      ;;
  esac

  __WEZTERM_REMOTE_DSK_CACHE=$(__wezterm_remote_metrics_disk)
  __WEZTERM_REMOTE_METRICS_LAST_COLLECT=$(__wezterm_remote_metrics_now)
}

__wezterm_remote_metrics_emit() {
  timestamp=$(__wezterm_remote_metrics_now)
  [ -n "$timestamp" ] || return 0

  __wezterm_remote_metrics_set_var WEZTERM_REMOTE_CPU "${__WEZTERM_REMOTE_CPU_CACHE:-}"
  __wezterm_remote_metrics_set_var WEZTERM_REMOTE_MEM "${__WEZTERM_REMOTE_MEM_CACHE:-}"
  __wezterm_remote_metrics_set_var WEZTERM_REMOTE_DSK "${__WEZTERM_REMOTE_DSK_CACHE:-}"
  __wezterm_remote_metrics_set_var WEZTERM_REMOTE_TS "$timestamp"
}

__wezterm_remote_metrics_update() {
  now=$(__wezterm_remote_metrics_now)
  [ -n "$now" ] || return 0

  needs_refresh=1
  if [ -n "${__WEZTERM_REMOTE_METRICS_LAST_COLLECT:-}" ]; then
    age=$((now - __WEZTERM_REMOTE_METRICS_LAST_COLLECT))
    if [ "$age" -lt "${WEZTERM_REMOTE_METRICS_INTERVAL:-8}" ]; then
      needs_refresh=0
    fi
  fi

  if [ "$needs_refresh" -ne 0 ] || [ -z "${__WEZTERM_REMOTE_DSK_CACHE:-}" ]; then
    __wezterm_remote_metrics_collect
  fi

  __wezterm_remote_metrics_emit
}

if [ "${__WEZTERM_REMOTE_METRICS_HOOKED:-0}" -ne 1 ]; then
  __WEZTERM_REMOTE_METRICS_HOOKED=1

  if [ -n "${BASH_VERSION:-}" ]; then
    case ";${PROMPT_COMMAND:-};" in
      *";__wezterm_remote_metrics_update;"*) ;;
      *)
        if [ -n "${PROMPT_COMMAND:-}" ]; then
          PROMPT_COMMAND="__wezterm_remote_metrics_update;${PROMPT_COMMAND}"
        else
          PROMPT_COMMAND="__wezterm_remote_metrics_update"
        fi
        ;;
    esac
  elif [ -n "${ZSH_VERSION:-}" ]; then
    autoload -Uz add-zsh-hook 2>/dev/null
    add-zsh-hook precmd __wezterm_remote_metrics_update 2>/dev/null
  fi
fi
