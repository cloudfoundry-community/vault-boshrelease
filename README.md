Vault - Secure Credentials Storage
==================================

Questions? Pop in our [slack channel](https://cloudfoundry.slack.com/messages/vault/)!

This [BOSH][bosh] release packages the excellent [Vault][vault]
software from [Hashicorp][hashicorp], so that you can run your own
secure credentials storage vault on your BOSH infrastructure,
today!


Getting Started on BOSH-lite
----------------------------

Before you can start spinning a vault, you will need to upload the
BOSH release to your director:

    bosh target https://192.168.50.4:25555
    bosh upload release https://bosh.io/d/github.com/cloudfoundry-community/vault-boshrelease

You can create a small, working manifest file from this git
repository:

    git clone https://github.com/cloudfoundry-community/vault-boshrelease
    cd vault-boshrelease
    ./templates/make_manifest warden
    bosh -n deploy

Vault should be up and running at
[http://10.244.8.3:8200](http://10.244.8.3:8200), but it still
needs some manual setup, due to security precautions.

First, you need to initialize the vault:

    export VAULT_ADDR=http://10.244.8.3:8200
    vault init

This generates a root encryption key for encrypting all of the
secrets.  At this point, the vault is _sealed_, and you will need
to unseal it three times, each time with a different key:

    vault unseal
    vault unseal
    vault unseal

Once unsealed, your vault should be ready for authentication with
your _initial root token_:

    vault auth

Now, you can put secrets in the vault, and read them back out:

    vault write secret/handshake knock=knock
    vault read secret/handshake

You may want to look at [safe][safe], an alternative command-line
utility for Vault that provides higher-level abstractions like
tree-based listing, secret generation, secure terminal password
entry, etc.


High Availability Concerns
--------------------------

If you put important things in your Vault, you want it to be
available, so you can get those important things back out again.

Enter High Availability.

The easiest way to do high availability is to run 3 or more nodes,
and use the Consul backend.  To do that, you're going to need to
load the Consul BOSH release from the Cloud Foundry Community:

    bosh upload release https://bosh.io/d/github.com/cloudfoundry-community/consul-boshrelease

(Having, of course, targeted your BOSH director first.  You _did_
target your BOSH director first, right?)

Then, just add the consul-y bits to your deployment manifest.
Here's a barebones (working) example to get you started:

```yaml
---
name: ha-vault

jobs:
- name: vault
  instances: 3
  resource_pool: vault
  persistent_disk: 4096
  networks:
    - name: vault
      static_ips: &ips
        - 10.244.8.2
        - 10.244.8.3
        - 10.244.8.4

  templates:
    - { release: vault,  name: vault  }
    - { release: consul, name: consul }

  properties:
    consul:
      join_hosts: *ips

    vault:
      backend:
        use_consul: true
```

Cloud Foundry Service Broker
----------------------------

Cloud Foundry developers/users can also access the multi-tenant Vault deployment via the Cloud Foundry service broker [`vault-broker`](https://github.com/cloudfoundry-community/vault-broker).

Once you have deployed vault once, initialized it, and obtained the token, you can now re-deploy Vault with the token to enable the service broker:

```
export VAULT_TOKEN=<TOKEN FROM vault init>
./make_manifest warden
bosh deploy
```

The service broker is now running on `10.244.8.2:5000` and has default credentials `vault:vault`.

As an example, to register it with Cloud Foundry running on the same bosh-lite:

```
cf create-service-broker vault vault vault http://10.244.8.2:5000
```

[BOSH]:      https://bosh.io
[vault]:     https://vaultproject.io
[hashicorp]: https://hashicorp.com
[safe]:      https://github.com/starkandwayne/safe
