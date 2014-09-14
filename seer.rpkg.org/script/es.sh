#! /bin/bash -eux

## Install Elasticsearch

wget -qO - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -

echo >> /etc/apt/sources.list \
     "deb http://packages.elasticsearch.org/elasticsearch/1.3/debian stable main"

apt-get -y update && apt-get -y install elasticsearch

## Java

## This is a trick to install Oracle JAva non-interactively
## Found at http://askubuntu.com/questions/190582

echo debconf shared/accepted-oracle-license-v1-1 select true | \
    debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | \
    debconf-set-selections

apt-get -y install software-properties-common
add-apt-repository -y ppa:webupd8team/java
apt-get update
apt-get -y install oracle-java7-installer

## Nginx for authentication

apt-get install -y nginx

cat > /etc/nginx/conf.d/elasticsearch_proxy.conf <<EOF
server {
  listen seer:9200;
  client_max_body_size 50M;

  error_log   /var/log/nginx/elasticsearch-errors.log;
  access_log  /var/log/nginx/elasticsearch.log;

  location ~ ^/(_search|cran-[a-zA-Z0-9]*/_search|cran-[a-zA-Z0-9]*/package/_search)$ {
    proxy_pass http://localhost:9200;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
  }

  location / {
      return 403;
  }

}

server {
  listen seer:5001;

  error_log   /var/log/nginx/elasticsearch-errors.log;
  access_log  /var/log/nginx/elasticsearch.log;

  location / {
    proxy_pass http://localhost:9200;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/es-passwd;
  }

}
EOF

## Password

sudo apt-get install apache2-utils

htpasswd -cb /etc/nginx/es-passwd admin "$ES_PASSWORD"

apt-get autoremote apache2-utils

## Restart nginx

service nginx restart

## Disable dynamic scripting

cat >> /etc/elasticsearch/elasticsearch.yml <<EOF
script.disable_dynamic: true
EOF

## Bind to localhost only

cat >> /etc/elasticsearch/elasticsearch.yml <<EOF
network.host: 127.0.0.1
http.host: 127.0.0.1
EOF

## Couchdb-river, and JS plugins

(
    cd /usr/share/elasticsearch
    bin/plugin -install elasticsearch/elasticsearch-river-couchdb/2.3.0
    bin/plugin -install elasticsearch/elasticsearch-lang-javascript/2.3.0
)

## Place ES scripts we need

mkdir /etc/elasticsearch/scripts
cat > /etc/elasticsearch/scripts/couch_river_filter.js <<EOF
var paste = function(d) {
  x = "";
  for (k in d) {
    x = x + k.toString() + " (" + d[k] + "), ";
  }
  return x;
};

var cran_filter = function(ctx) {
  // null object?
  if (!ctx.doc) {
    ctx.ignore = true;
    return ctx;
  }

  // If it is not a package,
  if (ctx.doc.type && ctx.doc.type != "package") {
    ctx.ignore = true;
    return ctx;
  }

  // Skip archivals
  if (ctx.doc.archived) {
    ctx.ignore = true;
    return ctx;
  }

  // Otherwise take the latest version
  if (ctx.doc.latest) {
    ctx.doc = ctx.doc.versions[ctx.doc.latest];
    // Squash dependency fields
    ctx.doc.Imports = paste(ctx.doc.Imports);
    ctx.doc.Depends = paste(ctx.doc.Depends);
    ctx.doc.Suggests = paste(ctx.doc.Suggests);
    ctx.doc.Enhances = paste(ctx.doc.Enhances);
    ctx.doc.LinkingTo = paste(ctx.doc.LinkingTo);
  } else {
    ctx.ignore = true;
  }

  return ctx;
};
ctx = cran_filter(ctx);
EOF

cat > /etc/elasticsearch/scripts/cran_search_score.mvel <<EOF
_score * (if (!doc['revdeps'].empty) doc['revdeps'].value + 1; else 1)
EOF

## Start elasticsearch

update-rc.d elasticsearch defaults 95 10
/etc/init.d/elasticsearch start
