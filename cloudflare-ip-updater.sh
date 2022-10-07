#!/bin/bash
#Basic CloudFlare API Script By Fixapc.net
#Updates A Record With IPv4 Address
#Updates AAAA Record With IPv6 Address
#Updates Cloudflare.com DNS Records 
#Youtube Channel: youtube.fixapc.net
#Note this is mainly for servers who act as a router / gateway at the moment and whos public IP resides on their network interface. 
#When i have more time i will update the script to automatically retrieve domains and have the IP be updated via Google.

#!/bin/bash
#User Specific Details here
key=
email=

#Your Domain List Here
domain=(
)

#Gets Your Ipv4 Global Address From The Previded Interface
     ipv4=$(curl -s https://api.ipify.org | strings || curl -s ifconfig.me | strings)

#Gets Your Ipv6 Global Address From The Previded Interface
     ipv6=$(ifconfig | rg -i -A1 $ipv4 | tail -n1 | awk '{print $2}' | strings )

#Echo Current IP On Specified Interface
     echo CURRENT IPv4 Address is $ipv4
     echo CURRENT IPv6 Address is $ipv6
#=====================START UPDATING CLOUDFLARE RECORDS=======================
for i in "${!domain[@]}"
do
echo " "
echo Attempting To Update ''${domain[i]}''s A Record To $ipv4
echo Attempting To Update ''${domain[i]}''s AAAA Record To $ipv6
echo " "
#Get Zone ID
     zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name="${domain[i]}"" \
          -H "X-Auth-Email: "$email"" \
          -H "X-Auth-Key: "$key"" \
          -H "Content-Type: application/json" \
             | json_pp | grep -E 'name|id' | sed -n 3p | awk '{print $3}' | tr -d [:punct:])

#Get A Record ID
     arecid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/"$zoneid"/dns_records/?type=A" \
          -H "X-Auth-Email: "$email"" \
          -H "X-Auth-Key: "$key"" \
          -H "Content-Type: application/json" \
          | json_pp | sed -n 8p | awk '{print $3}' | tr -d [:punct:])

#Get AAAA Record ID
     aaaarecid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/"$zoneid"/dns_records/?type=AAAA" \
          -H "X-Auth-Email: "$email"" \
          -H "X-Auth-Key: "$key"" \
          -H "Content-Type: application/json" \
          | json_pp | sed -n 8p | awk '{print $3}' | tr -d [:punct:])

#Update Domain1's A Record With Correct IPv4 Address
     echo A Record Update Results For ${domain[i]}
     curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/"$zoneid"/dns_records/"$arecid"" \
          -H "X-Auth-Email: "$email"" \
          -H "X-Auth-Key: "$key"" \
          -H "Content-Type: application/json" \
          --data '{"type":"A","name":"'${domain[i]}'","content":"'$ipv4'","ttl":3600,"proxied":false}' | json_pp | tr -d '""()[]{},' | column -t
#Add a space
echo
#Update Domain1's AAAA Record With Correct IPv6 Address
     echo AAAA Record Update Results For ${domain[i]}
      curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/"$zoneid"/dns_records/"$aaaarecid"" \
          -H "X-Auth-Email: "$email"" \
          -H "X-Auth-Key: "$key"" \
          -H "Content-Type: application/json" \
          --data '{"type":"AAAA","name":"'${domain[i]}'","content":"'$ipv6'","ttl":3600,"proxied":false}' | json_pp | tr -d '""()[]{},' | column -t
#Add a space
echo
done
