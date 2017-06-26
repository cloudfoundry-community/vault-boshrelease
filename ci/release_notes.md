# Improvements
- update vault binary to v0.7.3
- consume ssl certs from linked consul
- enable zero-downtime deployments via `step_down_token` and `unseal_keys`

# Breaking changes
- renamed all `backend` settings to `storage` in line with Vaults naming conventions.

# Fixes
- remove some redundant settings
