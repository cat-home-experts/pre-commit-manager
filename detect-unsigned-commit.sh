#!/usr/bin/env bash

has_error=0
signingKey=$(git config --global --get user.signingkey)

if [[ $signingKey == "" ]]; then
  echo "Commit unsigned !"
  # shellcheck disable=SC2034
  has_error=1
fi

#exit $has_error
