#!/bin/bash

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

export BROKER_ADDRESS="<%= p('vault.broker.address') %>"
export BROKER_USERNAME="<%= p('vault.broker.username') %>"
export BROKER_PASSWORD="<%= p('vault.broker.password') %>"

curl -u ${BROKER_USERNAME}:${BROKER_PASSWORD} ${BROKER_ADDRESS}/v2/catalog | jq .
