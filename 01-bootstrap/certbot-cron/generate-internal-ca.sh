#!/usr/bin/env bash
# ...existing CA generation steps...
openssl x509 -req -in rylan-ca.csr -CA rylan-ca.pem -CAkey rylan-ca.key -CAcreateserial -out rylan-ca.crt -days 3650 -sha256 \
  -extfile <(printf "crlDistributionPoints=URI:http://crl.rylan.internal/rylan-ca.crl")
