#!/usr/bin/env bash
# ...existing provisioning steps...

samba-tool domain exportkeytab /etc/krb5.keytab --principal=admin@RYLAN.INTERNAL
chmod 600 /etc/krb5.keytab
cp /etc/krb5.keytab /srv/tftp/krb5.keytab

echo "Provisioning complete"
