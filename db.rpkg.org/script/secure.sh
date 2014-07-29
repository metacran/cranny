#! /bin/bash -exu

ufw allow ssh
ufw allow http
ufw allow 5984
ufw --force enable

cat >/tmp/FWD <<EOF
# Forward http to CouchDB
*nat
:PREROUTING ACCEPT [0:0]
-A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 5984
COMMIT

EOF

cp /etc/ufw/before.rules /etc/ufw/before.rules.bak
cat /tmp/FWD /etc/ufw/before.rules >/tmp/FWD2 && 
cp /tmp/FWD2 /etc/ufw/before.rules

ufw reload
