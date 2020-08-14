Vault - Secure Credentials Storage
==================================

**NOTE**: This BOSH release has a lot of configuration options,
and is intended more for people who want to tinker with Vault and
its various storage backends.  If you are looking for a
**rock-solid** Vault deployment on BOSH, check out the [safe BOSH
Release](https://github.com/cloudfoundry-community/safe-boshrelease)
instead.

Questions? Pop in our [slack channel][slack]

This [BOSH][bosh] release packages the excellent [Vault][vault]
software from [Hashicorp][hashicorp], primarily for tinkering,
experimentation.

  - Release engineering and testing by [Stark & Wayne Concourse][ci]
  - All PRs will be run through CI/CD (see `testflight-pr` job)

## Usage

To use this BOSH release:

```
$ export BOSH_ENVIRONMENT=<alias>
$ export BOSH_DEPLOYMENT=vault

$ git clone https://github.com/cloudfoundry-community/vault-boshrelease.git
$ cd vault-boshrelease
$ bosh deploy manifests/vault.yml --vars-store tmp/creds.yml
```

If your BOSH has Credhub/Config Server, then you do not need
`--vars-store`. Rather certificates/credentials will be generated
and stored within Credhub. Subsequent instructions below will
continue to use `--vars-store` examples.

Run `bosh instances` to get the IP address for one of your Vault
instances:

```
$ bosh instances

Instance                                    Process State  AZ  IPs
vault/259fbc67-0a0f-4714-a122-f3370ffd5bd6  running        z3  10.244.0.187
vault/5a692a5e-260a-414f-9906-6e1ccbf66433  running        z2  10.244.0.186
vault/9f34f839-92a0-4827-a713-c43a2430c0d9  running        z1  10.244.0.185
```

Next you need to initialize the Vault. Connect via port `:8200`:

```
$ export VAULT_ADDR=https://10.244.0.187:8200
$ export VAULT_SKIP_VERIFY=true
$ vault operator init
```

This generates a root encryption key for encrypting all of the
secrets.  At this point, the vault is _sealed_, and you will need
to unseal it three times, each time with a different key:

```
$ vault operator unseal
$ vault operator unseal
$ vault operator unseal
```

Once unsealed, your Vault should be ready for authentication with
your _initial root token_:

```
$ vault login
```

Now, you can put secrets in the Vault, and read them back out (try
any path with `secret/` prefix):

```
$ vault write secret/handshake knock=knock
$ vault read secret/handshake
```

You may want to look at [safe][safe], an alternative command-line
utility for Vault that provides higher-level abstractions like
tree-based listing, secret generation, secure terminal password
entry, etc.

## Configuration

### Template Strings

As the base manifest shows, a full HCL configuration can be
assigned to the `vault.config` property. If you're using Vault in
HA mode (which is recommended) you'll probably need to set values
like `api_addr` and `cluster_address`.  The `vault.config`
property supports the following template strings to make setting
these values easier:

**`(ip)`**

During deployment this value will be replaced with the IP address
of the instance. This will not include the protocol or any port
information. For example for an IP based configuration:

```hcl
storage "consul" {
  path = "vault/"
  check_timeout = "5s"
  max_parallel = "128"
}
api_addr = "http://(ip):8200"
cluster_addr = "https://(ip):8201"
```

**`(index)`**

During deployment this value will be replaced with the index of
the instance. This can be particularly useful for DNS
configuration values. For example, if you were deploying 3
instances, this would ensure each one had a unique DNS value in
its configuration::

```hcl
storage "consul" {
  path = "vault/"
  check_timeout = "5s"
  max_parallel = "128"
}
api_addr = "http://vault-(index).yoursite.biz:8200"
cluster_addr = "https://vault-(index).yoursite.biz:8201"
```
### Certificate Management

Your Vault configuration is likely going to require TLS. This
release's `vault.tls` property can lets you provide these
certificates:

```yaml
properties:
  tls:
    - name: "my_tls_cert"
      cert: |
        -----BEGIN CERTIFICATE-----
        CertBlockAsRawText
        -----END CERTIFICATE-----
      key: ((or_use_a_variable))

    - name: "other_tls_cert"
      cert: ((other_tls_certificate_content))
      key: ((other_tls_key_content))
```

The above configuration will create the following files on the
Vault instance before starting Vault:

  - `/var/vcap/jobs/vault/tls/my_tls_cert/cert.pem`
  - `/var/vcap/jobs/vault/tls/my_tls_cert/key.pem`
  - `/var/vcap/jobs/vault/tls/other_tls_cert/cert.pem`
  - `/var/vcap/jobs/vault/tls/other_tls_cert/key.pem`

### Management of Additional Configuration Files

Vault's configuration supports lots of cool features that sometimes require additional configuration files be present.
An example of this is GCP auto unsealing. To support these kinds of cases this Bosh release provides the 
`additional_config` property.

```
properties:
  vault:
    additional_config:
      - name: gcp.json
        config: |
          {
            "some":"valid_json"
          }
```

The above configuration will create the file `/var/vcap/jobs/vault/config/gcp.json` on the Vault instance before 
starting Vault.

### Monit Script Configuration

In order to enable features like zero downtime redeploys this Bosh release
bundles scripts that utilize the Vault CLI. Manifest properties are available to
explicitly set the value of the `VAULT_SKIP_VERIFY` and `VAULT_ADDR`
environment variables in the context of these monit scripts:

```yaml
  properties:
    vault:
      skip_verify: false                      #default if absent
      addr:        "https://127.0.0.1:8200"   #default if absent
```

Prior to 1.0.0 release, the `VAULT_SKIP_VERIFY` environment
variable is set if the vault address contains `https`, so
connecting to the vault server on 127.0.0.1 (during unseal) would
not throw an SSL exception. Since 1.0.0 release, the environmental
variable is no longer  set  by default. There are several possible
ways to address the situation.

- If you have **only one** vault node, you can use
  `properties.vault.addr` to set `VAULT_ADDR` environmental variable
  according to your cert CN.

- If you have more than one nodes, **and** can use SAN IP entry of
  `127.0.0.1` in your certs, leave out `properties.vault.addr`
  (using the default).

- If you have more than one nodes, and can _NOT_ use SAN IP entry
  of `127.0.0.1` in your certs, you need to specify
  `vault.skip_verify`, and leave out `vault.addr`. This breaks the
  [security model][security], though minor since the communication
  is at the local host.

Zero Downtime Updates
---------------------

To enable zero-downtime updates you must provide an auth token
that is authorized to perform `vault step-down`. Once you have
unsealed vault you can set it up as follows:

```
$ cat > step-down.hcl <<EOF
path "sys/step-down" {
  capabilities = ["update", "sudo"]
}
EOF

$ vault policy write step-down ./step-down.hcl
Policy 'step-down' written.
$ vault token create -policy="step-down" -display-name="step-down" -no-default-policy -orphan
Key             Value
---             -----
token           STEP-DOWN-TOKEN
token_accessor  cf37c98a-685a-1cf0-fc2e-4bd21a4a6be2
token_duration  768h0m0s
token_renewable true
token_policies  [step-down]
```

Then add the token value to your deployment file under
`properties.vault.update.step_down_token`. This will cause Vault
to perform a controlled failover before updating each individual
node.

Once the update of a node has completed it will need to be
unsealed. If you add your unseal keys under
`properties.vault.update.unseal_keys` this will also be taken care
of. This will make the entire update process truely zero-downtime
ie. when using a consul-agent to provide dns, the domain name
`vault.service.consul` should always be pointing to a Vault that
will accept connections.

```
$ bosh deploy manifests/vault.yml --vars-store tmp/creds.yml \
  -o manifests/operators/step-down-token.yml \
  -v "vault-step-down-token=STEP-DOWN-TOKEN" \
  -v "vault-unseal-keys=[UNSEAL1,UNSEAL2,UNSEAL3]"
```


It is highly recommended to run `vault rekey` after an update
where the unseal keys were provided have taken place to not leave
the keys exposed in the manifest.

**WARNING!!!** If you add the unseal keys to your manifest and do
not rekey once the deployment is done then it will be possible for
anyone with access to the manifest to decrypt and see all secrets
stored in vault.

You will provide three of the original unseal keys to `vault
rekey`, so run it three times to generate new unseal keys:

```
$ vault operator rekey
$ vault operator rekey
$ vault operator rekey
```

See [rekeying and rotating][rekey] (in the Vault documentation)
for additional instructions.

[BOSH]:      https://bosh.io
[vault]:     https://vaultproject.io
[hashicorp]: https://hashicorp.com
[slack]:     https://cloudfoundry.slack.com/messages/vault/
[ci]:        https://ci.starkandwayne.com/teams/main/pipelines/vault-boshrelease
[safe]:      https://github.com/starkandwayne/safe
[rekey]:     https://www.vaultproject.io/guides/rekeying-and-rotating.html
[security]:  https://www.vaultproject.io/docs/commands/index.html#vault_skip_verify
