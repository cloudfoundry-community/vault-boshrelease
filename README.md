Vault - Secure Credentials Storage
==================================

**NOTE**: This BOSH release has a lot of configuration options,
and is intended more for people who want to tinker with Vault and
its various storage backends.  If you are looking for a
**rock-solid** Vault deployment on BOSH, check out the [safe BOSH
Release](https://github.com/cloudfoundry-community/safe-boshrelease)
instead.

Questions? Pop in our [slack channel](https://cloudfoundry.slack.com/messages/vault/)!

This [BOSH][bosh] release packages the excellent [Vault][vault]
software from [Hashicorp][hashicorp], so that you can run your own
secure credentials storage vault on your BOSH infrastructure,
today!

* [Concourse CI](https://ci.starkandwayne.com/teams/main/pipelines/vault-boshrelease)
* Pull requests will be automatically tested against a bosh-lite (see `testflight-pr` job)
* Discussions and CI notifications at [#vault channel](https://cloudfoundry.slack.com/messages/C22176QDP/) on https://slack.cloudfoundry.org

One of the fastest ways to get [vault](https://about.vault.com/) running on any infrastructure is to deploy this bosh release.

* [Concourse CI](https://ci.starkandwayne.com/teams/main/pipelines/vault-boshrelease)
* Discussions and CI notifications at [#vault channel](https://cloudfoundry.slack.com/messages/C22176QDP/) on https://slack.cloudfoundry.org

## Usage

To use this bosh release, first upload it to your bosh:

```
export BOSH_ENVIRONMENT=<alias>
export BOSH_DEPLOYMENT=vault

git clone https://github.com/cloudfoundry-community/vault-boshrelease.git
cd vault-boshrelease
bosh deploy manifests/vault.yml --vars-store tmp/creds.yml
```

If your BOSH has Credhub/Config Server, then you do not need `--vars-store`. Rather certificates/credentials will be generated and stored within Credhub. Subsequent instructions below will continue to use `--vars-store` examples.

Run `bosh instances` to get the IP address for one of your Vault instances:

```
$ bosh instances

Instance                                    Process State  AZ  IPs
vault/259fbc67-0a0f-4714-a122-f3370ffd5bd6  running        z3  10.244.0.187
vault/5a692a5e-260a-414f-9906-6e1ccbf66433  running        z2  10.244.0.186
vault/9f34f839-92a0-4827-a713-c43a2430c0d9  running        z1  10.244.0.185
```

Next you need to initialize the Vault. Connect via port `:8200`:

```
export VAULT_ADDR=https://10.244.0.187:8200
export VAULT_SKIP_VERIFY=true
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

Now, you can put secrets in the vault, and read them back out (try any path with `secret/` prefix):

```
vault write secret/handshake knock=knock
vault read secret/handshake
```

You may want to look at [safe][safe], an alternative command-line
utility for Vault that provides higher-level abstractions like
tree-based listing, secret generation, secure terminal password
entry, etc.

### Configuration

As the base manifest shows, a full HCL configuration can be assigned to the `vault.config` property. If you're using 
Vault in HA mode (which is recommended) you'll probably need to set vaules like `redirect_address` and `cluster_address`.
The `vault.config` property supports the following template strings to make setting these values easier: 

**`(ip)`**

During deployment this value will be replaced with the IP address of the instance. This will not include the protocol or
any port information. For example for an IP based configuration:

```hcl
storage "consul"{
  path = "vault/"
  check_timeout = "5s"
  max_parallel = "128"
  cluster_address = "https://(ip):8200"
  redirect_address = "https://(ip):8200"
}
```

**`(index)`**

During deployment this value will be replaced with the index of the instance. This can be particularly useful for DNS
configuration values. For example, if you were deploying 3 instances, this would ensure each one had a unique DNS value
in its configuration:

```hcl
storage "consul"{
  path = "vault/"
  check_timeout = "5s"
  max_parallel = "128"
  cluster_address = "https://prod-vault-(index).yoursite.biz"
  redirect_address = "https://prod-vault-(index).yoursite.biz"
}
```

High Availability Concerns
--------------------------

If you put important things in your Vault, you want it to be
available, so you can get those important things back out again.

Enter High Availability.

The easiest way to do high availability is to run 3 or more nodes,
and use the Consul storage.

Fortunately, the `manifests/vault.yml` manifest in the [Usage](#usage) section above is already a 3-node high availability cluster.

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
token          	STEP-DOWN-TOKEN
token_accessor 	cf37c98a-685a-1cf0-fc2e-4bd21a4a6be2
token_duration 	768h0m0s
token_renewable true
token_policies  [step-down]
```

Then add the token value to your deployment file under `properties.vault.update.step_down_token`. This will cause Vault to perform a controlled failover before updating each individual node.

Once the update of a node has completed it will need to be unsealed. If you add your unseal keys under `properties.vault.update.unseal_keys` this will also be taken care of. This will make the entire update process truely zero-downtime ie. when using a consul-agent to provide dns, the domain name `vault.service.consul` should always be pointing to a Vault that will accept connections.

```
bosh deploy manifests/vault.yml --vars-store tmp/creds.yml \
  -o manifests/operators/step-down-token.yml \
  -v "vault-step-down-token=STEP-DOWN-TOKEN" \
  -v "vault-unseal-keys=[UNSEAL1,UNSEAL2,UNSEAL3]"
```


It is highly recommend to run `vault rekey` after an update where the unseal_keys were provided have taken place to not leave the keys exposed in the manifest.

**WARNING!!!** If you add the unseal keys to your manifest and do not rekey once the deployment is done then it will be possible for anyone with access to the manifest to decrypt and see all secrets stored in vault.

You will provide three of the original unseal keys to `vault rekey`, so run it three times to generate new unseal keys:

```
vault rekey
vault rekey
vault rekey
```

See https://www.vaultproject.io/guides/rekeying-and-rotating.html for additional instructions

Cloud Foundry Service Broker
----------------------------

Cloud Foundry developers/users can also access the multi-tenant Vault deployment via the Cloud Foundry service broker [`vault-broker`](https://github.com/cloudfoundry-community/vault-broker).

Once you have deployed vault once, initialized it, and obtained the token, you can now re-deploy Vault with the token to enable the service broker:

```
cf_deployment=<name of cf deployment in BOSH, e.g. 'cf'>
system_domain=$(bosh -d $cf_deployment manifest | bosh int - --path /instance_groups/name=api/jobs/name=cloud_controller_ng/properties/system_domain)
skip_verify=$(bosh -d $cf_deployment manifest | bosh int - --path /instance_groups/name=api/jobs/name=cloud_controller_ng/properties/ssl/skip_cert_verify)
admin_password=$(bosh -d $cf_deployment manifest | bosh int - --path /instance_groups/name=uaa/jobs/name=uaa/properties/uaa/scim/users/name=admin/password)

bosh deploy manifests/vault.yml --vars-store tmp/creds.yml \
  -o manifests/operators/servicebroker.yml \
  -v "cf-system-domain=$system_domain" \
  -v cf-api-url=https://api.$system_domain \
  -v cf-skip-ssl-validation=$skip_verify \
  -v cf-admin-username=admin \
  -v "cf-admin-password=$admin_password" \
  -v "vault-token=<token from vault init>"
```

NOTE: if you are using Credhub then consider inserting `vault-token` and `cf-admin-password` as a secret into Credhub rather than pass it as `-v` argument above.

To register the service broker with Cloud Foundry:

```
bosh run-errand broker-registrar
```

[BOSH]:      https://bosh.io
[vault]:     https://vaultproject.io
[hashicorp]: https://hashicorp.com
[safe]:      https://github.com/starkandwayne/safe
