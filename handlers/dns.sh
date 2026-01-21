#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

domains=$(grep -oE '([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}')
all_ips=""

y "domain:"
push
for domain in ${domains}; do
  y "- name: ${domain}"
  push
  IPS=$(dig +short A "${domain}")
  all_ips="${all_ips} ${IPS}"
  y "ipv4:"
  push
  for ip in $IPS; do
    y "- ip: ${ip}"
  done
  pop
  NS_SERVERS=$(dig +short NS "${domain}")
  y "ns:"
  push
  for ns in $NS_SERVERS; do
    y "- nameserver: ${ns}"
    push
    y "ipv4:"
    push
    NS_IPS=$(dig +short A "${ns}")
    all_ips="${all_ips} ${NS_IPS}"
    for ns_ip in $NS_IPS; do
      y "- ip: ${ns_ip}"
    done
    pop
    pop
  done
  pop
  MX_SERVERS=$(dig +short MX "${domain}" | cut -d" " -f2)
  y "mx:"
  push
  for mx in ${MX_SERVERS}; do
    y "- mailserver: ${mx}"
    push
    y "ipv4:"
    push
    MX_IPS=$(dig +short A "${mx}")
    all_ips="${all_ips} ${MX_IPS}"
    for mx_ip in $MX_IPS; do
      y "- ip: ${mx_ip}"
    done
    pop
    pop
  done
  pop
  pop
done

for ip in $all_ips; do
  echo $ip | ${SCRIPT_DIR}/ip4.sh $tmpdir "Ip ${ip}" #> ${tmpdir}/${ip}.yaml
done
