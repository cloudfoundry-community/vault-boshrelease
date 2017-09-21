Vault - Secure Credentials Storage
==================================

Questions? Pop in our [slack channel](https://cloudfoundry.slack.com/messages/vault/)!

This [BOSH][bosh] release packages the excellent [Vault][vault]
software from [Hashicorp][hashicorp], so that you can run your own
secure credentials storage vault on your BOSH infrastructure,
today!

* [Concourse CI](https://ci.starkandwayne.com/teams/main/pipelines/vault-boshrelease)
* Pull requests will be automatically tested against a bosh-lite (see `testflight-pr` job)
* Discussions and CI notifications at [#vault channel](https://cloudfoundry.slack.com/messages/C22176QDP/) on https://slack.cloudfoundry.org

Getting Started on BOSH-lite
----------------------------

To use this bosh release, first upload it to your bosh:

```
export BOSH_ENVIRONMENT=<alias>
export BOSH_DEPLOYMENT=gogs

git clone https://github.com/cloudfoundry-community/gogs-boshrelease.git
cd gogs-boshrelease
bosh deploy manifests/gogs.yml
```

To discover the allocated IP addresses:

```
bosh instances
```

In the examples below, it assumes one of the Vault instances has the IP address `10.244.8.3`.

Vault should be up and running but it still needs some manual setup, due to security precautions.

First, you need to initialize the vault:

```
export VAULT_ADDR=http://10.244.8.3:8200
vault init
```

This generates a root encryption key for encrypting all of the
secrets.  At this point, the vault is _sealed_, and you will need
to unseal it three times, each time with a different key:

```
vault unseal
vault unseal
vault unseal
```

Once unsealed, your vault should be ready for authentication with
your _initial root token_:

```
vault auth
```

Now, you can put secrets in the vault, and read them back out:

```
vault write secret/handshake knock=knock
vault read secret/handshake
```

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
and use the Consul storage.

Fortunately, the base manifest `manifests/vault.yml` does this by default.

Zero Downtime Updates
---------------------

To enable zero-downtime updates you must provide an auth token that is authorized to perform `vault step-down`. Once you have unsealed vault you can set it up as follows:

```
$ cat > step-down.hcl <<EOF
path "sys/step-down" {
  capabilities = ["update", "sudo"]
}
EOF
$ vault policy-write step-down ./step-down.hcl
Policy 'step-down' written.
$ vault token-create -policy="step-down" -display-name="step-down" -no-default-policy -orphan
Key             Value
---             -----
token           0687a4b0-4305-40da-b668-988abd7d056a
token_accessor  b0da7605-0963-5328-7a8d-cff258c805f3
token_duration  768h0m0s
token_renewable true
token_policies  [step-down]
```

Then add the token value to your deployment file under `properties.vault.update.step_down_token`. This will cause Vault to perform a controlled failover before updating each individual node.

Once the update of a node has completed it will need to be unsealed. If you add your unseal keys under `properties.vault.update.unseal_keys` this will also be taken care of. This will make the entire update process truely zero-downtime ie. when using a consul-agent to provide dns, the domain name `vault.service.consul` should always be pointing to a Vault that will accept connections.

It is highly recommend to run `vault rekey` after an update where the unseal_keys were provided have taken place to not leave the keys exposed in the manifest.
WARNING!!! If you add the unseal keys to your manifest and do not rekey once the deployment is done then it will be possible for anyone with access to the manifest to decrypt and see all secrets stored in vault.

[BOSH]:      https://bosh.io
[vault]:     https://vaultproject.io
[hashicorp]: https://hashicorp.com
[safe]:      https://github.com/starkandwayne/safe
