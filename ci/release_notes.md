## Build / Dev Changes

The vault-boshrelease pipeline now tracks the vault-broker
releases and pulls them into this BOSH release semi-automagically,
to help keep it up-to-date.

## New Software

### vault
Bumped https://github.com/hashicorp/vault to v0.8.3

### vault-broker
Bumped https://github.com/cloudfoundry-community/vault-broker to v0.0.1

This version of vault-broker fixes a bug in unbinding with the
Vault API.  Users are encouraged to upgrade as soon as possible if
they are using the Cloud Foundry vault-broker service broker.
