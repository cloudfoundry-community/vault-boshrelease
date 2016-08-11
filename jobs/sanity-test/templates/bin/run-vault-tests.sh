#!/bin/bash

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables
set -x # print commands

test_value=knock-$(date +"%s" | rev)

vault write secret/handshake sanity-test=${test_value}
read_value=$(vault read secret/handshake | grep sanity-test | awk '{print $2}')
if [[ "${read_value}" != "${test_value}" ]]; then
  echo "ERROR: vault did not return same value written"
  exit 1
fi

vault delete secret/handshake
