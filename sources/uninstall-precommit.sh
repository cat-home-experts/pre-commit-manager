#!/usr/bin/env bash
# shellcheck disable=SC2143,SC2015
set -e

installer_location="$HOME/.local/var/pre-commit-manager"


answer=n
if [[ "$1" != "-q" ]]; then
  read -r -p 'Do you want to remove the pre-commit hooks deployer cron jobs [y/N]: ' answer
else
  answer=y
fi

if [[ "${answer}" == "y" ]]; then
  # Delete the 1st job definition
  croncmd="/bin/bash -l -c '${installer_location}/deploy_hooks.sh'"
  if [[ -n "$(crontab -l | grep "$croncmd")" ]]; then
    ( crontab -l | grep -v -F "$croncmd" ) | crontab -
    echo -e "\033[1;32m[✓]\033[0m Hooks deployer cron job removed"
  fi

  # Delete the 2nd job
  croncmd="/bin/bash -l -c 'pre-commit gc'"
  if [[ -n "$(crontab -l | grep "$croncmd")" ]]; then
    ( crontab -l | grep -v -F "$croncmd" ) | crontab -
    echo -e "\033[1;32m[✓]\033[0m pre-commit cache cleanup job removed"
  fi
fi


answer=n; answer2=n
if [[ "$1" != "-q" ]]; then
  read -r -p 'Do you want to remove the pre-commit hooks from all your repositories [y/N]: ' answer
  read -r -p 'Do you also want to remove all pre-commit baseline configs (.yaml) [y/N]: ' answer2
else
  answer=y; answer2=y
fi

if [[ "${answer}" == "y" ]]; then
  if [[ -n "${PRECOMMIT_EXCLUDE}" || -n "${PRECOMMIT_INCLUDE}" ]]; then
    echo -e "\033[1;37m\033[41mMake sure to empty your environment variales '\$PRECOMMIT_EXCLUDE' and '\$PRECOMMIT_INCLUDE' if you want to cleanup ALL repositories\033[0m"
  fi

  # Build the find parameters to exclude/include any folders declared in the bash environment
  custom_exclusion_filter=""
  # shellcheck disable=SC2153
  for pattern in ${PRECOMMIT_EXCLUDE//,/ }; do
    custom_exclusion_filter="$custom_exclusion_filter -o -path '$pattern' -prune"
  done

  custom_inclusion_filter=""
  # shellcheck disable=SC2153
  for pattern in ${PRECOMMIT_INCLUDE//,/ }; do
    pattern="${pattern}/.git"
    if [[ "${custom_inclusion_filter}" == "" ]]; then
      custom_inclusion_filter="-path '$pattern'"
    else
      custom_inclusion_filter="$custom_inclusion_filter -o -path '$pattern'"
    fi
  done

  # Build the git repo list located on the hard drive under the HOME directory
  repo_exclusion_list=$(eval "find $HOME -type d \
    -not \( \
      -path '${HOME}/Library' -prune \
      -o -path '${HOME}/Pictures' -prune \
      -o -path '${HOME}/.*' -prune \
      -o -path '*.terraform/*' -prune \
      -o -path '*.terragrunt-cache/*' -prune \
      -o -path '*.history/*' -prune \
      ${custom_exclusion_filter} \
    \) \
    -iname '.git' -prune" \
  )

  # shellcheck disable=SC2153
  if [[ -n "${PRECOMMIT_INCLUDE}" ]]; then
    repo_inclusion_list=$(eval "find $HOME -type d \
      -not \( \
        -path '${HOME}/Library' -prune \
        -o -path '${HOME}/Pictures' -prune \
        -o -path '${HOME}/.*' -prune \
        -o -path '*.terraform/*' -prune \
        -o -path '*.terragrunt-cache/*' -prune \
        -o -path '*.history/*' -prune \
      \) \
      \( ${custom_inclusion_filter} \) \
      -prune" \
    )
  fi

  repo_list="$(sort -u <(printf '%s\n' "${repo_exclusion_list}") <(printf '%s\n' "${repo_inclusion_list}"))"
  # shellcheck disable=SC2207
  repo_array=($(echo "${repo_list}" | tr ' ' ','))
  total_count=${#repo_array[@]}

  final_answer=n
  if [[ "$1" != "-q" ]]; then
    read -r -p "About to remove pre-commit hooks from ${total_count} repos, do you want to proceed [y/N]: " final_answer
  else
    final_answer=y
  fi

  if [[ "${final_answer}" == "y" ]]; then
    for repo in ${repo_list}; do
      repo_path="${repo%/.git}"
      echo -e "\033[1;32m[✓]\033[0m repo \033[1;34m${repo_path}\033[0m"
      if [[ "${answer2}" == "y" ]]; then
        if [[ -f "${repo_path}/.pre-commit-config.yaml" ]]; then
          rm -f "${repo_path}/.pre-commit-config.yaml"
          echo -e "   * pre-commit manager baseline config removed..."
        fi
      fi
      if [[ -f "${repo_path}/.git/hooks/commit-msg" || -f "${repo_path}/.git/hooks/pre-commit" || -f "${repo_path}/.git/hooks/pre-push" ]]; then
        cd "${repo_path}"
        [[ -n "$(command -v pre-commit)" ]] && printf '%s\n' "   * $(pre-commit uninstall)" || true
        rm "${repo_path}/.git/hooks/commit-msg" 2>/dev/null && echo -e "   * Hook commit-msg removed"
        rm "${repo_path}/.git/hooks/pre-commit" 2>/dev/null && echo -e "   * Hook pre-commit removed"
        rm "${repo_path}/.git/hooks/pre-push" 2>/dev/null && echo -e "   * Hook pre-push removed"
        cd - &>/dev/null
      fi
    done
  fi
fi

# Clean out cached pre-commit files
[[ -n "$(command -v pre-commit)" ]] && pre-commit clean || true

answer=n
if [[ "$1" != "-q" ]]; then
  read -r -p 'Do you want to uninstall the pre-commit framework binaries (pre-commit itself) [y/N]: ' answer
else
  answer=y
fi

if [[ "${answer}" == "y" ]]; then
  if python -m pip uninstall pre-commit 2>/dev/null || python3 -m pip uninstall pre-commit 2>/dev/null || npm uninstall -g pre-commit 2>/dev/null; then
    echo -e "\033[1;32m[✓]\033[0m pre-commit framework binaries removed"
  else
    echo -e "\033[1;37m\033[41mNo relevant package manager found. You will need to install python+pip or npm to uninstall pre-commit.\033[0m"
  fi
fi


answer=n
if [[ "$1" != "-q" ]]; then
  read -r -p 'Do you want to remove the pre-commit manager sources [y/N]: ' answer
else
  answer=y
fi

if [[ "${answer}" == "y" ]]; then
  rm -rf "${installer_location}"
  echo -e "\033[1;32m[✓]\033[0m Nuked everything. You can sleep like a log..."
fi
