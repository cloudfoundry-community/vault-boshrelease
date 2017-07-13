## Bug Fixes

- Fixed a variable naming bug, so that `VAULT_ADVERTISE_ADDR` is
  properly set so that `vault` can take advantage of it.
  (We had mistakenly left the critical `_ADDR` part off...)
