# Improvements
- use spec.ip to determin own ip address (compatible with BOSH-release v258+)

# Changes
- Remove consuming ssl certs from linked consul. The hostnames will need to be set for vault rendering the certs unusable.
