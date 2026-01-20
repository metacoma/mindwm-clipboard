#!/usr/bin/env bash

ssh_tmux_session_list() {
    ssh seed.mgmt.mansion.shitcluster.io 'tmux list-sessions \; list-windows -a' \
    | awk '
    BEGIN {
      print "        tmux_sessions:"
    }
    /^[^:]+:[0-9]+:/ {
      session=$1
      sub(/:.*/, "", session)

      window=$2
      gsub(/[*Z-]/, "", window)

      if (!(session in seen)) {
        print "          " session ":"
        seen[session]=1
      }

      print "            - " window
    }
    '
}

ssh_host_by_ip() {
    local ip="$1"
    local cfg="$HOME/.ssh/config"

    awk -v ip="$ip" '
        BEGIN {
            host=""
        }
        /^\s*Host[[:space:]]+/ {
            host=$2
        }
        /^\s*HostName[[:space:]]+/ && $2 == ip {
            print host
            exit
        }
    ' "$cfg"
}

ipv4_is_public() {
  local ip="$1"

  ipcalc -c "$ip" >/dev/null 2>&1 || return 1

  ipcalc -n -b "$ip" \
    | grep -iqE 'PRIVATE|LOOPBACK|LINKLOCAL|MULTICAST|RESERVED' \
    && return 1

  return 0
}

get_country() {
  local ip_addr=$1
  mmdblookup --file geoip/GeoLite2-City.mmdb --ip ${ip_addr} country iso_code \
| sed -n 's/.*"\(.*\)".*/\1/p' | tail -n1
}

get_org() {
  local ip_addr=$1
  mmdblookup \
    --file geoip/GeoLite2-ASN.mmdb \
    --ip "$ip_addr" \
    autonomous_system_organization \
  | sed -n 's/.*"\(.*\)".*/\1/p' | tail -n1
}

get_city() {
  local ip="$1"
  local lang="${2:-en}"

  mmdblookup \
    --file geoip/GeoLite2-City.mmdb \
    --ip "$ip" \
    city names "$lang" 2>/dev/null \
  | sed -n 's/.*"\(.*\)".*/\1/p' \
  | tail -n1
}


tmpdir="${1:?tmpdir is required}"
IPS=`grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u`

test -z "$IPS" && exit 0

echo "ip4:"
for ip in $IPS; do
  echo "  - ip: $ip"
  country=""
  ipv4_is_public $ip && {
    country=$(get_country $ip)
    test -n "${country}" && \
      echo "    country: $country"
    org=$(get_org $ip)
    test -n "${org}" && \
      echo "    org: $org"
    city=$(get_city $ip)
    test -n "${city}" && \
      echo "    city: $city"
  } || :

  hostname=$(ssh_host_by_ip $ip)

  test -n "${hostname}" && {
      echo "    ssh:"
      echo "        hostname: ${hostname}"
      ssh_tmux_session_list ${hostname}
  } || :
done
