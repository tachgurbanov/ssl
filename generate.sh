#!/usr/bin/env bash

# Read input
PROJECT_NAME=${1-'project-name'}
PROJECT_SUB_DOMAINS=${2-''}

# Define variables
BIN_OPENSSL=/usr/bin/openssl
LOCAL_CERT_PATH=$(pwd -P)/ssl
LOCAL_CERT_CERT=${LOCAL_CERT_PATH}/${PROJECT_NAME}.crt
LOCAL_CERT_KEY=${LOCAL_CERT_PATH}/${PROJECT_NAME}.key
LOCAL_CERT_MAIN_DOMAIN=${PROJECT_NAME}.localhost
LOCAL_CERT_EXTRA_DOMAINS=,DNS.2:*.${PROJECT_NAME}.localhost
declare -a LOCAL_CERT_DOMAINS=(${PROJECT_NAME}.localhost *.${PROJECT_NAME}.localhost)

# Parse optional sub domains
if [ ! -z "$PROJECT_SUB_DOMAINS" ]; then
    SUB_DOMAINS=(${PROJECT_SUB_DOMAINS//,/ })
    SUB_DOMAIN_INDEX=3

    for i in "${!SUB_DOMAINS[@]}"
    do
        SUB_DOMAIN=${SUB_DOMAINS[$i]}.${PROJECT_NAME}.localhost
        LOCAL_CERT_EXTRA_DOMAINS=${LOCAL_CERT_EXTRA_DOMAINS},DNS.${SUB_DOMAIN_INDEX}:${SUB_DOMAIN}
        SUB_DOMAIN_INDEX=$((SUB_DOMAIN_INDEX+1))

        LOCAL_CERT_DOMAINS+=(${SUB_DOMAIN})
    done
fi

# Generate SSL certificate
${BIN_OPENSSL} req -x509 -out ${LOCAL_CERT_CERT} -keyout ${LOCAL_CERT_KEY} \
-newkey rsa:2048 -nodes -sha256 \
-subj "/CN=${LOCAL_CERT_MAIN_DOMAIN}" -extensions EXT -config <( \
printf "[dn]\nCN=${LOCAL_CERT_MAIN_DOMAIN}\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS.1:${LOCAL_CERT_MAIN_DOMAIN}${LOCAL_CERT_EXTRA_DOMAINS}\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

# Show results
echo ""
echo "New SSL certificate was generated:"
echo "- Certificate: ${LOCAL_CERT_CERT}"
echo "- Key: ${LOCAL_CERT_KEY}"
echo ""
echo "DNS Names:"
for DOMAIN in "${LOCAL_CERT_DOMAINS[@]}"
do
    echo "- ${DOMAIN}"
done
