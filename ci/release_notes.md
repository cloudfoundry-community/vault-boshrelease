## Breaking changes

* `vault-broker` properties `vault.broker.username` and `vault.broker.password` have been renamed `username` and `password` respectively. This is to allow the job to be supported by the `broker-registrar-boshrelease`.

## Updates

* Add support for the `vault.config` property, which can be used to pass an HCL string literal representation of Vault's configuration. Passing this value will take precedence over any other defined configuration properties. TLS certs and keys will still need to be passed as properties so they can be rendered by their respective template files.
* `manifests/vault.yml` has default `vm_type`, `persistent_disk_type` and `network` name that matches the `cloud-config` from `cf-deployment` project. See `manifests/operators/scale.yml` for an operator file to modify these values.
* README has been updated to recommend the bosh2 manifests and operator files
* `manifests/operators/servicebroker.yml` will add the `vault-broker` job in a new instance
* `vault-broker` will attempt to discover vault cluster via local consul (`localhost:8500`) if explicit backend address not provided; this feature is used in the

# vault
Bumped https://github.com/hashicorp/vault to v0.9.5

# vault
Bumped https://github.com/hashicorp/vault to v0.9.6
