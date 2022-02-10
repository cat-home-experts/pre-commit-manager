#!/usr/bin/env bash
set -e

main() {
  _initialize
  _parse_cmdline "$@"

  if [[ -z "$(command -v terraform-docs)" ]]; then
    echo "\033[1;37m\033[41mYou should install 'terraform-docs' first to be able to use its hook.\033[0m"
    exit 0
  fi

  if [ "$DEBUG" == "true" ]; then
    echo "Inputs: $*"
    echo "var ARGS: ${ARGS[*]}"
    echo "var ENVS: ${ENVS[*]}"
    echo "var FOLDERS: ${FOLDERS[*]}"
    echo "var EXCLUDED_PATHS: ${EXCLUDED_PATHS[*]}"
  fi

  _run_hook
}

_run_hook() {
  local is_excluded
  local cmd
  local check_docs
  local root_dir
  root_dir="$(git rev-parse --show-toplevel)"

  for folder in "${FOLDERS[@]}"; do
    check_docs=
    is_excluded=false
    # We make sure we don't run the command on a filtered path
    for excluded_path in "${EXCLUDED_PATHS[@]}"; do
      if [[ "${folder}" =~ ${excluded_path} ]]; then
        is_excluded=true
        break
      fi
    done

    if [ "$is_excluded" == "false" ]; then
      # If the documentation exists, we prepare it for docs injection the first time
      if [[ -f "${folder}/README.md" && ! "$(cat "${folder}/README.md")" == *'<!-- BEGIN_TF_DOCS -->'* ]]; then
        find "$folder" -type f -iname 'README.md' -not \( -path '*.terraform/*' -prune -o -path '*.terragrunt-cache/*' -prune -o -path '*tests/*' -prune \) | xargs -n1 -Ifile -- bash -c 'printf "\n\n%s\n%s\n" "<!-- BEGIN_TF_DOCS -->" "<!-- END_TF_DOCS -->" >> "file"'
      fi
      cmd="terraform-docs markdown table --output-file README.md --output-mode inject ${ARGS[*]}"
      check_docs=$(terraform-docs markdown table --output-file README.md --output-mode inject --output-check "${folder}" 2>&1 || true)

      if [[ "$check_docs" == *"out of date"* ]]; then
        echo "Updating documentation in: ${folder#"${root_dir}/"}"
        ${cmd} "$folder" 1>/dev/null
      fi
    fi
  done
}

_parse_cmdline() {
  declare argv
  argv=$(getopt -o e:a:f:x:d: --long env:,arg:,folder:,exclude-path:,debug: -- "$@") || return
  argv_for_logging=$(getopt -o e:a:f:x:d: --long env:,arg:,folder:,exclude-path:,debug: -- "$@")
  eval "set -- $argv"

  for argv; do
    case $argv in
      -a | --arg)
        shift
        ARGS+=("$1")
        shift
        ;;
      -e | --env)
        shift
        ENVS+=("$1")
        shift
        ;;
      -f | --folder)
        shift
        FOLDERS+=("$(_to_abs_path "$1")")
        shift
        ;;
      -x | --exclude-path)
        shift
        EXCLUDED_PATHS+=("$(_to_abs_path "$1")")
        shift
        ;;
      -d | --debug)
        shift
        [[ "$1" == "true" ]] && DEBUG=true
        shift
        ;;
      --)
        shift
        FILES=("$@")
        break
        ;;
    esac
  done

  # Setup environment variables
  local var var_name var_value
  for var in "${ENVS[@]}"; do
    var_name="${var%%=*}"
    var_value="${var#*=}"
    # shellcheck disable=SC2086
    export $var_name="$var_value"
  done

  if [ "$DEBUG" == "true" ]; then
    echo "Inputs Parsed: ${argv_for_logging}"
  fi

  _derive_folders_from_native_files
}

_derive_folders_from_native_files() {
  # As terragrunt operates recursively, if '--folder' isn't used,
  # we get the folders from the 'files' pre-commit native parameter
  local path_uniq
  local absolute_path
  local index=0
  if [ ${#FOLDERS[@]} -eq 0 ]; then
    for path_uniq in $(echo "${FILES[*]}" | tr ' ' '\n' | sort -u); do
      path_uniq="${path_uniq// /__REPLACED__SPACE__}"
      absolute_path="$(_to_abs_path "$(dirname "$path_uniq")")"
      FOLDERS[index]="${absolute_path}"
      ((index += 1))
    done
  fi
}

_to_abs_path() {
  local target="$1"

  if [ "$target" == "." ]; then
    pwd
  elif [ "$target" == ".." ]; then
    dirname "$(pwd)"
  else
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
  fi
}

_initialize() {
  # get directory containing this script
  local dir
  local source
  source="${BASH_SOURCE[0]}"

  while [[ -L $source ]]; do # resolve $source until the file is no longer a symlink
    dir="$(cd -P "$(dirname "$source")" > /dev/null && pwd)"
    source="$(readlink "$source")"
    # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    [[ $source != /* ]] && source="$dir/$source"
  done
  _SCRIPT_DIR="$(dirname "$source")"

  # source getopt function
  # shellcheck disable=SC1091
  . "${_SCRIPT_DIR}/lib-getopt.sh"
}

# global arrays
declare -a ARGS
declare -a ENVS
declare -a FOLDERS
declare -a EXCLUDED_PATHS
declare -a FILES
DEBUG=false

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
