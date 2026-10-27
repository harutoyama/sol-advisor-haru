#!/bin/sh
# Install Sol Advisor's model-specific custom-agent templates without changing Codex config.

set -eu

usage() {
  cat <<'EOF'
Usage: install-agents.sh [--target-dir PATH] [--check] [--check-role ROLE ...] [--upgrade-known]

Roles: luna-exploration, luna-worker, luna-testing, luna-implementation, terra-implementation, sol-review, luna-research, terra-research

Normal mode installs the eight current profiles. It never overwrites modified, symlinked,
non-regular, conflicting, or obsolete Sol Advisor profiles. --check is non-mutating.
--check-role is repeatable and implies --check. --upgrade-known explicitly upgrades
only pristine prior-release Terra 5.6 profiles to Terra 6.1; any other changed
content still blocks the entire install before mutation.

Haru fork 0.7.0 capability profiles are migration hazards. If present, the installer
classifies and reports them, performs no mutation, and exits nonzero. Remove or archive only
the exact reported files after inspection, then rerun.
EOF
}

fail() {
  printf '%s\n' "ERROR: $*" >&2
  exit 1
}

exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

sha256_file() {
  path=$1
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" 2>/dev/null | awk 'NF >= 1 && length($1) == 64 { print $1; exit }'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" 2>/dev/null | awk 'NF >= 1 && length($1) == 64 { print $1; exit }'
  else
    return 1
  fi
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
    luna-exploration) source=$luna_explorer_template; file=$luna_explorer_file ;;
    luna-worker) source=$luna_worker_template; file=$luna_worker_file ;;
    luna-testing) source=$luna_tester_template; file=$luna_tester_file ;;
    luna-implementation) source=$luna_template; file=$luna_file ;;
    terra-implementation) source=$terra_template; file=$terra_file ;;
    sol-review) source=$sol_template; file=$sol_file ;;
    luna-research) source=$luna_research_template; file=$luna_research_file ;;
    terra-research) source=$terra_research_template; file=$terra_research_file ;;
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
    case "$source_path" in
      "$terra_template"|"$terra_research_template")
        # Accept only the exact old distributed template with its former model line.
        # All other modifications (including comments) remain protected.
        if grep -Fqx 'model = "gpt-6.1-terra"' "$source_path" &&
           sed 's/^model = "gpt-6.1-terra"$/model = "gpt-5.6-terra"/' "$source_path" |
             cmp -s - "$destination"; then
          printf '%s\n' legacy-terra
        else
          printf '%s\n' conflict
        fi
        ;;
      *) printf '%s\n' conflict ;;
    esac
  fi
}

classify_obsolete() {
  destination=$1
  expected_digest=$2
  if ! exists "$destination"; then
    printf '%s\n' absent
  elif [ -L "$destination" ] || [ ! -f "$destination" ]; then
    printf '%s\n' unsafe
  else
    digest=$(sha256_file "$destination" || true)
    if [ -n "$digest" ] && [ "$digest" = "$expected_digest" ]; then
      printf '%s\n' exact-0.7.0
    else
      printf '%s\n' modified-or-unknown
    fi
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

upgrade_one() {
  source_path=$1
  destination=$2
  staged=$(mktemp "$target_dir/.sol-advisor-agent.XXXXXX") ||
    fail "could not create upgrade staging file for $destination"
  if ! cp "$source_path" "$staged"; then
    rm -f "$staged"
    fail "could not stage upgrade of $destination"
  fi
  if [ "$(classify "$source_path" "$destination")" != legacy-terra ]; then
    rm -f "$staged"
    fail "destination changed after preflight; refusing upgrade: $destination"
  fi
  if ! mv -f "$staged" "$destination"; then
    rm -f "$staged"
    fail "could not atomically replace prior pristine Terra profile: $destination"
  fi
  printf '%s\n' "UPGRADED: $destination"
}

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 1
template_dir=$script_dir/../agents

if [ -n "${CODEX_HOME-}" ]; then
  target_dir=$CODEX_HOME/agents
else
  [ -n "${HOME-}" ] || fail "HOME is unset; set CODEX_HOME or pass --target-dir."
  target_dir=$HOME/.codex/agents
fi

check_only=0
check_roles=''
upgrade_known=0

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
    --upgrade-known)
      upgrade_known=1
      shift
      ;;
    --check-role)
      [ "$#" -ge 2 ] || fail "--check-role requires a role."
      case "$2" in
        luna-exploration|luna-worker|luna-testing|luna-implementation|terra-implementation|sol-review|luna-research|terra-research) ;;
        *) fail "unknown --check-role '$2'; expected luna-exploration, luna-worker, luna-testing, luna-implementation, terra-implementation, sol-review, luna-research, or terra-research." ;;
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

luna_explorer_file=sol-advisor-luna-explorer.toml
luna_worker_file=sol-advisor-luna-worker.toml
luna_tester_file=sol-advisor-luna-tester.toml
luna_file=sol-advisor-luna-implementer.toml
terra_file=sol-advisor-terra-implementer.toml
sol_file=sol-advisor-sol-reviewer.toml
luna_research_file=sol-advisor-luna-researcher.toml
terra_research_file=sol-advisor-terra-researcher.toml

luna_explorer_template=$template_dir/$luna_explorer_file
luna_worker_template=$template_dir/$luna_worker_file
luna_tester_template=$template_dir/$luna_tester_file
luna_template=$template_dir/$luna_file
terra_template=$template_dir/$terra_file
sol_template=$template_dir/$sol_file
luna_research_template=$template_dir/$luna_research_file
terra_research_template=$template_dir/$terra_research_file

obsolete_delegate=sol-advisor-delegate-implementer.toml
obsolete_escalation=sol-advisor-escalation-implementer.toml
obsolete_audit=sol-advisor-audit-reviewer.toml

obsolete_delegate_sha256=1594d2ac0fa527301b92afaf635a14a4e89b640d20f8673b6406d87298bc31c5
obsolete_escalation_sha256=85a257f74155ea717c4591acb3c24667d1498d5fbc3244029fda6290f7f080af
obsolete_audit_sha256=b11c1c8a9773cfbcb62fa855f7723bbf5fc9df4cf91a5c9dc2be2a01b898f597

for template in "$luna_explorer_template" "$luna_worker_template" "$luna_tester_template" "$luna_template" "$terra_template" "$sol_template" "$luna_research_template" "$terra_research_template"; do
  [ -f "$template" ] && [ ! -L "$template" ] ||
    fail "shipped template is missing or unsafe: $template"
done

if exists "$target_dir" && { [ -L "$target_dir" ] || [ ! -d "$target_dir" ]; }; then
  fail "target directory is not a real directory: $target_dir"
fi

obsolete_found=0
for spec in \
  "$obsolete_delegate:$obsolete_delegate_sha256" \
  "$obsolete_escalation:$obsolete_escalation_sha256" \
  "$obsolete_audit:$obsolete_audit_sha256"
do
  name=${spec%%:*}
  expected=${spec#*:}
  path=$target_dir/$name
  state=$(classify_obsolete "$path" "$expected")
  case "$state" in
    absent) ;;
    exact-0.7.0)
      printf '%s\n' "OBSOLETE 0.7.0 UNMODIFIED: $path" >&2
      obsolete_found=1
      ;;
    modified-or-unknown)
      printf '%s\n' "OBSOLETE MODIFIED OR UNKNOWN: $path" >&2
      obsolete_found=1
      ;;
    unsafe)
      printf '%s\n' "OBSOLETE UNSAFE: $path" >&2
      obsolete_found=1
      ;;
    *) fail "internal obsolete classification error for $path" ;;
  esac
done

if [ "$obsolete_found" -ne 0 ]; then
  fail "obsolete 0.7.0 capability profiles remain; no changes were made. Inspect the exact reported paths, remove or archive only files you have verified, then rerun."
fi

preflight_failed=0
for role in luna-exploration luna-worker luna-testing luna-implementation terra-implementation sol-review luna-research terra-research; do
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
    legacy-terra)
      if [ "$upgrade_known" -ne 1 ] || [ "$check_only" -eq 1 ]; then
        printf '%s\n' "ERROR: old Terra profile needs explicit --upgrade-known: $destination" >&2
        preflight_failed=1
      fi
      ;;
    unsafe)
      printf '%s\n' "ERROR: unsafe destination: $destination" >&2
      preflight_failed=1
      ;;
    conflict)
      printf '%s\n' "ERROR: modified or stale destination will not be overwritten: $destination" >&2
      preflight_failed=1
      ;;
    *) fail "internal classification error for $destination" ;;
  esac
done
[ "$preflight_failed" -eq 0 ] || exit 1

if [ "$check_only" -eq 1 ]; then
  for role in luna-exploration luna-worker luna-testing luna-implementation terra-implementation sol-review luna-research terra-research; do
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

for role in luna-exploration luna-worker luna-testing luna-implementation terra-implementation sol-review luna-research terra-research; do
  role_paths "$role"
  destination=$target_dir/$file
  case "$(classify "$source" "$destination")" in
    current) printf '%s\n' "UNCHANGED: $destination" ;;
    missing) install_one "$source" "$destination" ;;
    legacy-terra)
      [ "$upgrade_known" -eq 1 ] || fail "explicit upgrade flag lost"
      upgrade_one "$source" "$destination"
      ;;
    *) fail "destination changed after preflight: $destination" ;;
  esac
done

for role in luna-exploration luna-worker luna-testing luna-implementation terra-implementation sol-review luna-research terra-research; do
  role_paths "$role"
  destination=$target_dir/$file
  [ "$(classify "$source" "$destination")" = current ] ||
    fail "post-install verification failed: $destination"
done

printf '%s\n' "Installed Sol Advisor custom-agent profiles. Start or continue with the primary model and effort you selected; only auxiliary agent profiles have fixed model/effort pins."
