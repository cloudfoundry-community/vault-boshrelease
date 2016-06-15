# Feature: High Availibility Support

Added vault.ha.\* properties for HA Vault

- `vault.ha.name` specifies the hostname portion of the advertised FQDN
	(for non-leader -> leader handoff redirection)
- `vault.ha.domain` specifies the domain portion of the advertised FQDN

This should be enough to support HA (with an HA-friendly backend like
Consul), assuming you can set up a single SSL/TLS certificate as a
wildcard, or with subjectAltNames for all individually named components.

