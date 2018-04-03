**This release contains BREAKING CHANGES to
backwards-compatibility**

Almost all of the configuration properties have been removed.
In their place, a single `vault.config` property has been
created to house a complete HCL string, as a multi-line block.

The new `vault.tls` allows operators to specify the certificates
and keys that their configuration (`vault.config`) uses.

Refer to the `manifests/vault.yml` example deployment manifest for
details on how to use `vault.tls` and `vault.config` in concert.

The `vault-broker` job has been removed from this release.  If you
would like a more _packaged_ BOSH experience, you are encouraged
to migrate to the [safe BOSH release][safe-bosh].

## Updates

- The BOSH 2.0 manifest `manifests/vault.yml` now has default
  cloud-config parameters that match those of `cf-deployment`.
  Operators can modify these by including the `scale` ops file.

- Bumped https://github.com/hashicorp/vault to v0.9.6
