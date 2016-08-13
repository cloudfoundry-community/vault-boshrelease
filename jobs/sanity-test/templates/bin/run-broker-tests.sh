#!/bin/bash

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

export PATH=/var/vcap/jobs/sanity-test/bin:$PATH
export BROKER_URI=http://<%= p("vault.broker.username") %>:<%= p("vault.broker.password") %>@<%= p("vault.broker.host") %>:<%= p("vault.broker.port") %>
echo $BROKER_URI

curl -u ${BROKER_URI}/v2/catalog | jq .

service_id=$(curl -sf ${BROKER_URI}/v2/catalog | jq -r ".services[0].id")
plan_ids=$(curl -sf ${BROKER_URI}/v2/catalog | jq -r ".services[0].plans[].id")
instance_id=T-$(date +"%s" | rev)
binding_id=B-$(date +"%s" | rev)

for plan_id in ${plan_ids[@]}; do

  credentials=$(create-service $service_id $plan_id $instance_id $binding_id)
  echo $credentials
  export VAULT_TOKEN=$(echo $credentials | jq -r ".credentials.token")
  export VAULT_ADDR=$(echo $credentials | jq -r ".credentials.vault")

  vault status
  
  root_path=$(echo $credentials | jq -r ".credentials.root")

  test_value=knock-$(date +"%s" | rev)

  vault write ${root_path}/handshake sanity-test=${test_value}
  read_value=$(vault read ${root_path}/handshake | grep sanity-test | awk '{print $2}')
  if [[ "${read_value}" != "${test_value}" ]]; then
    echo "ERROR: vault did not return same value written"
    exit 1
  fi

  vault delete ${root_path}/handshake

  delete-service $service_id $plan_id $instance_id $binding_id
done
