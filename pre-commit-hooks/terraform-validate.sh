#!/usr/bin/env bash
set -e

main() {
  _initialize
  _parse_cmdline "$@"

  if [[ -z "$(command -v terraform)" ]]; then
    echo "\033[1;37m\033[41mYou should install 'terraform' first to be able to use its hook.\033[0m"
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
  local error

  for folder in "${FOLDERS[@]}"; do
    is_excluded=false
    error=0
    # We make sure we don't run the command on a filtered path
    for excluded_path in "${EXCLUDED_PATHS[@]}"; do
      if [[ "${folder}" =~ ${excluded_path} ]]; then
        is_excluded=true
        break
      fi
    done

    if [ "$is_excluded" == "false" ]; then

      pushd "$folder" > /dev/null
      if [[ ! -d .terraform ]]; then
        set +e
        init_output=$(terraform init -backend=false 2>&1)
        init_code=$?
        set -e

        if [[ $init_code != 0 ]]; then
          error=1
          echo "Init before validation failed for $folder"
          echo "$init_output"
          popd > /dev/null
          continue
        fi
      fi

      set +e
      validate_output=$(terraform validate "${ARGS[*]}" 2>&1)
      validate_code=$?
      set -e

      if [[ $validate_code != 0 ]]; then
        if [[ "$validate_output" == *"Plugin reinitialization required"* || "$validate_output" == *"Module not installed"* || "$validate_output" == *"Module source has changed"* ]]; then
          set +e
          # Retry mechanism
          init_output=$(terraform init -backend=false 2>&1)
          init_code=$?
          validate_output=$(terraform validate "${ARGS[*]}" 2>&1)
          validate_code=$?
          set -e
        fi
        if [[ $validate_code != 0 ]]; then
          error=1
          echo "Validation failed for $folder"
          echo "$validate_output"
        fi
      fi

      set +e
      validate_output=$(tflint --enable-rule=terraform_unused_declarations 2>&1)
      validate_code=$?
      set -e
      if [[ $validate_code != 0 ]]; then
        error=1
        echo "Terraform declaration validation failed for $folder"
        echo "$validate_output"
        echo
      fi

      popd > /dev/null

    fi
  done

  if [[ $error -ne 0 ]]; then
    exit 1
  fi
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
