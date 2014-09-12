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
  listen $(hostname):9200;
  client_max_body_size 50M;

  error_log   /var/log/nginx/elasticsearch-errors.log;
  access_log  /var/log/nginx/elasticsearch.log;

  location ~ ^/(_search|cran-[a-zA-Z0-9]*/_search)$ {
    proxy_pass http://localhost:9200;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
  }

  location / {
      return 403;
  }

}

server {
  listen $(hostname):5001;

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

## Place ES scripts we need

# TODO

## Start elasticsearch

update-rc.d elasticsearch defaults 95 10
/etc/init.d/elasticsearch start
