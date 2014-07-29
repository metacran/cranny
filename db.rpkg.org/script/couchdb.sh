#!/bin/bash -eu

# Need to give some time to the DB to start
apt-get -y install couchdb && sleep 5

# Admin party by default, so no password is needed
HOST=http://127.0.0.1:5984

# Create DB
curl --fail -X PUT $HOST/cran
curl --fail -X GET $HOST/cran

# Config: bind to all interfaces
cat <<EOF >> /etc/couchdb/local.d/bind.ini
[httpd]
bind_address = 0.0.0.0
EOF
chown couchdb:couchdb /etc/couchdb/local.d/bind.ini

# Config: virtual host. Note that it is still possible to 
# use the IP address and then there is no virtual host.
cat <<EOF > /etc/couchdb/local.d/vhost.ini
[vhosts]
db.r-pkg.org = /cran/_design/app/_rewrite
EOF
chown couchdb:couchdb /etc/couchdb/local.d/vhost.ini

# Install node, npm, couchapp
apt-get -y install nodejs npm
npm install couchapp

# Push DB schema
curl --fail -O https://raw.githubusercontent.com/metacran/tools/master/app.js
nodejs node_modules/.bin/couchapp push app.js $HOST/cran
curl --fail -X GET $HOST/cran/_design/app

# Supervisor password, we do this directly in the DB,
# because CouchDB will salt and hash it.
curl --fail -X PUT $HOST/_config/admins/admin -d \"$COUCHDB_PASSWORD\"

# Restart CouchDB, need to wait a bit, otherwise the
# modifications are lost (!).
sleep 5 && service couchdb restart

# Remove unneeded packages, files
rm -rf node_modules app.js tmp .npm 
apt-get -y autoremove --purge nodejs npm
