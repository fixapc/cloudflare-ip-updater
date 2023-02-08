#!/bin/bash

# Array of domains to update
domains=(
your domains here
)

# Cloudflare API credentials
auth_email="your cloudflare email here"
auth_key="your global api key here"

# Get the current public IP address
current_ip=$(curl -s https://ipv4.icanhazip.com)

# Loop through each domain in the array
for domain in "${domains[@]}"; do
  # Get the zone ID for the domain
  zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain}" \
    -H "X-Auth-Email: ${auth_email}" \
    -H "X-Auth-Key: ${auth_key}" \
    -H "Content-Type: application/json" \
    | jq -r '.result[0].id')

  # Check if the zone ID was found
  if [ ! -z "$zone_id" ]; then
    # Get the current DNS records for the domain
    dns_records=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?type=A,AAAA&name=${domain}" \
      -H "X-Auth-Email: ${auth_email}" \
      -H "X-Auth-Key: ${auth_key}" \
      -H "Content-Type: application/json")

    # Check if the A record exists
    a_record_id=$(echo "$dns_records" | jq -r ".result[] | select(.type == \"A\") | .id")
    if [ ! -z "$a_record_id" ]; then
      # Update the A record
      curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${a_record_id}" \
        -H "X-Auth-Email: ${auth_email}" \
        -H "X-Auth-Key: ${auth_key}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"${domain}\",\"content\":\"${current_ip}\",\"ttl\":1,\"proxied\":false}"
    fi

    # Check if the AAAA record exists
    aaaa_record_id=$(echo "$dns_records" | jq -r ".result[] | select(.type == \"AAAA\") | .id")
    if [ ! -z "$aaaa_record_id" ]; then
      # Update the AAAA record
      curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${aaaa_record_id}" \
        -H "X-Auth-Email: ${auth_email}" \
        -H "X-Auth-Key: ${auth_key}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"AAAA\",\"name\":\"${domain}\",\"content\":\"${current_ip}\",\"ttl\":1,\"proxied\":false}"
    fi
  fi
done

