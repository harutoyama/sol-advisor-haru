#!/bin/sh
# Install Sol Advisor custom-agent templates without changing Codex configuration.

set -eu

usage() {
  cat <<'EOF'
Usage: install-agents.sh [--target-dir PATH] [--check] [--check-role ROLE ...]

Roles: delegate, escalation, audit

Normal mode installs the three current profiles. It never overwrites modified, symlinked,
non-regular, or obsolete Sol Advisor profiles. --check is non-mutating. --check-role is
repeatable and implies --check.
EOF
}

fail() {
  printf '%s\n' "ERROR: $*" >&2
  exit 1
}

exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

selected() {
  role=$1
  [ -z "$check_roles" ] && return 0
  case ",$check_roles," in
    *,"$role",*) return 0 ;;
    *) return 1 ;;
  esac
}

role_paths() {
  case "$1" in
    delegate) source=$delegate_template; file=$delegate_file ;;
    escalation) source=$escalation_template; file=$escalation_file ;;
    audit) source=$audit_template; file=$audit_file ;;
    *) fail "internal unknown role: $1" ;;
  esac
}

classify() {
  source_path=$1
  destination=$2
  if ! exists "$destination"; then
    printf '%s\n' missing
  elif [ -L "$destination" ] || [ ! -f "$destination" ]; then
    printf '%s\n' unsafe
  elif cmp -s "$source_path" "$destination"; then
    printf '%s\n' current
  else
    printf '%s\n' conflict
  fi
}

install_one() {
  source_path=$1
  destination=$2
  staged=$(mktemp "$target_dir/.sol-advisor-agent.XXXXXX") ||
    fail "could not create staging file for $destination"
  if ! cp "$source_path" "$staged"; then
    rm -f "$staged"
    fail "could not stage $destination"
  fi
  if ! ln "$staged" "$destination"; then
    rm -f "$staged"
    fail "destination changed after preflight; refusing overwrite: $destination"
  fi
  rm -f "$staged"
  printf '%s\n' "INSTALLED: $destination"
}

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 1
template_dir=$script_dir/../agents

if [ -n "$CODEX_HOME" ] 2>/dev/null; then
  target_dir=$CODEX_HOME/agents
else
  [ -n "$HOME" ] 2>/dev/null || fail "HOME is unset; set CODEX_HOME or pass --target-dir."
  target_dir=$HOME/.codex/agents
fi

check_only=0
check_roles=''

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target-dir)
      [ "$#" -ge 2 ] || fail "--target-dir requires a path."
      [ -n "$2" ] || fail "--target-dir requires a non-empty path."
      case "$2" in --*) fail "option-like target path must be prefixed with ./ or be absolute." ;; esac
      target_dir=$2
      shift 2
      ;;
    --check)
      check_only=1
      shift
      ;;
    --check-role)
      [ "$#" -ge 2 ] || fail "--check-role requires a role."
      case "$2" in
        delegate|escalation|audit) ;;
        *) fail "unknown --check-role '$2'; expected delegate, escalation, or audit." ;;
      esac
      check_only=1
      check_roles=$check_roles$2,
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

case "$target_dir" in
  /*) ;;
  *) target_dir=$(pwd -P)/$target_dir ;;
esac
[ "$target_dir" != "/" ] || fail "refusing filesystem root as target."

delegate_file=sol-advisor-delegate-implementer.toml
escalation_file=sol-advisor-escalation-implementer.toml
audit_file=sol-advisor-audit-reviewer.toml

delegate_template=$template_dir/$delegate_file
escalation_template=$template_dir/$escalation_file
audit_template=$template_dir/$audit_file

for template in "$delegate_template" "$escalation_template" "$audit_template"; do
  [ -f "$template" ] && [ ! -L "$template" ] ||
    fail "shipped template is missing or unsafe: $template"
done

if exists "$target_dir" && { [ -L "$target_dir" ] || [ ! -d "$target_dir" ]; }; then
  fail "target directory is not a real directory: $target_dir"
fi

legacy_found=0
for legacy in   sol-advisor-luna-implementer.toml   sol-advisor-terra-implementer.toml   sol-advisor-sol-reviewer.toml
do
  legacy_path=$target_dir/$legacy
  if exists "$legacy_path"; then
    printf '%s\n' "OBSOLETE: $legacy_path" >&2
    legacy_found=1
  fi
done
if [ "$legacy_found" -ne 0 ]; then
  fail "obsolete Sol Advisor profiles remain; inspect and remove or archive the reported paths manually, then retry."
fi

preflight_failed=0
for role in delegate escalation audit; do
  selected "$role" || continue
  role_paths "$role"
  destination=$target_dir/$file
  state=$(classify "$source" "$destination")
  case "$state" in
    missing)
      [ "$check_only" -eq 0 ] || {
        printf '%s\n' "ERROR: missing role profile: $destination" >&2
        preflight_failed=1
      }
      ;;
    current) ;;
    unsafe)
      printf '%s\n' "ERROR: unsafe destination: $destination" >&2
      preflight_failed=1
      ;;
    conflict)
      printf '%s\n' "ERROR: modified destination will not be overwritten: $destination" >&2
      preflight_failed=1
      ;;
    *) fail "internal classification error for $destination" ;;
  esac
done
[ "$preflight_failed" -eq 0 ] || exit 1

if [ "$check_only" -eq 1 ]; then
  for role in delegate escalation audit; do
    selected "$role" || continue
    role_paths "$role"
    destination=$target_dir/$file
    [ "$(classify "$source" "$destination")" = current ] ||
      fail "role changed during check: $destination"
    printf '%s\n' "OK: $role -> $destination"
  done
  exit 0
fi

if ! exists "$target_dir"; then
  mkdir -p "$target_dir" || fail "could not create target directory: $target_dir"
fi
[ -d "$target_dir" ] && [ ! -L "$target_dir" ] ||
  fail "target directory became unsafe: $target_dir"

for role in delegate escalation audit; do
  role_paths "$role"
  destination=$target_dir/$file
  case "$(classify "$source" "$destination")" in
    current) printf '%s\n' "UNCHANGED: $destination" ;;
    missing) install_one "$source" "$destination" ;;
    *) fail "destination changed after preflight: $destination" ;;
  esac
done

for role in delegate escalation audit; do
  role_paths "$role"
  destination=$target_dir/$file
  [ "$(classify "$source" "$destination")" = current ] ||
    fail "post-install verification failed: $destination"
done

printf '%s\n' "Installed Sol Advisor agent profiles. Start a fresh Codex task."
