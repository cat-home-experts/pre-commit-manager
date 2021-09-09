#!/usr/bin/env bash

# An Ansible vault encrypted file header contains the value below
VAULT_ENC_SIGNATURE='ANSIBLE_VAULT'
SPECIFIC_STRING='username'

set -e
has_error=0

for file in "$@" ; do
  # Test the existence of the right header
  # shellcheck disable=SC2143
  if [ -z "$(head -1 "$file" | grep --no-messages "$VAULT_ENC_SIGNATURE")" ] ||
    [ "$(echo cat "$file" | tr '[:upper:]' '[:lower:]' | grep --no-messages "$SPECIFIC_STRING")" ]; then
      has_error=1
      echo "ERROR: $file is not encrypted"
  fi
done

if [ $has_error -eq 1 ] ; then
    echo "Please encrypt the file(s) with 'ansible-vault encrypt <file>'. Or force the commit/push with '--no-verify'."
fi

exit $has_error
