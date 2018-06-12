# Improvements

- The new `vault.skip_verify` property allows you to use
  self-signed certificates, or other untrusted X.509 certs,
  with the automatic unseal bits.  Previously, this would
  fail because the vault CLI was not seeing `VAULT_SKIP_VERIFY`
  in the environment.

  This is off by default, preserving the legacy (more secure)
  behavior.

- The new `vault.addr` property allows you to target the correct
  IP or domain name, in the event that you are using a real,
  trusted X.509 certificate.

# Bug Fixes

- Various documentation, example, and README updates were made.
  Whee!

- Empty keys are skippined the automatic `vault unseal` step, if
  you are using that functionality.

# Software Updates

- Bumped Vault binary to v0.10.2
