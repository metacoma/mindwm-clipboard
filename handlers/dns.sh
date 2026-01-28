#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

extract_real_domains() {
  local TLD_FILE="${1:-${SCRIPT_DIR}/tlds-alpha-by-domain.txt}"

  grep -aoE '([A-Za-z0-9-]+\.)+[A-Za-z]{2,}\.?' \
  | tr 'A-Z' 'a-z' \
  | sed 's/\.$//' \
  | sort -u \
  | awk -F. -v tldfile="$TLD_FILE" '
      BEGIN {
        while ((getline t < tldfile) > 0) {
          if (t ~ /^#/) continue
          T[tolower(t)] = 1
        }
      }
      {
        if (T[$NF]) print
      }
    '
}

domains=$(extract_real_domains)
all_ips=""

test -n "${domains}" || exit 0

y "domain:"
push
for domain in ${domains}; do
  y "- name: ${domain}"
  push
  IPS=$(dig +short A "${domain}" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
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

if [[ -z "${all_ips//[[:space:]]/}" ]]; then
  exit 1
fi

for ip in $all_ips; do
  echo $ip | ${SCRIPT_DIR}/ip4.sh $tmpdir "Ip ${ip}" #> ${tmpdir}/${ip}.yaml
done
