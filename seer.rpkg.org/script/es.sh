#! /bin/bash -eu

## Install Elasticsearch

wget -qO - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -

echo >> /etc/apt/sources.list \
     "deb http://packages.elasticsearch.org/elasticsearch/1.3/debian stable main"

apt-get -y update && apt-get -y install elasticsearch

## Need Java for Jetty
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

## Install Jetty

wget http://central.maven.org/maven2/org/mortbay/jetty/dist/jetty-deb/8.1.14.v20131031/jetty-deb-8.1.14.v20131031.deb \
     -O jetty-deb-8.1.14.v20131031.deb
dpkg -i jetty-deb-8.1.14.v20131031.deb

## Start Jetty

update-rc.d jetty defaults 94 11
/etc/init.d/jetty start

## Install Jetty plugin for Elasticsearch

apt-get -y install unzip

(
    cd /usr/share/elasticsearch/plugins/
    mkdir -p jetty
    cd jetty
    wget https://github.com/gaborcsardi/elasticsearch-jetty/releases/download/v1.2.3-beta/elasticsearch-jetty-1.2.3-beta.zip
    unzip elasticsearch-jetty*.zip
)

cat >> /etc/elasticsearch/elasticsearch.yml <<EOF
http.type: com.sonian.elasticsearch.http.jetty.JettyHttpServerTransportModule
sonian.elasticsearch.http.jetty:
    config: jetty.xml,jetty-hash-auth.xml,jetty-restrict-writes.xml,jetty-gzip.xml
EOF

## Disable dynamic scripting

cat >> /etc/elasticsearch/elasticsearch.ym <<EOF
script.disable_dynamic: true
EOF

## Place ES scripts we need

# TODO

## Start elasticsearch

update-rc.d elasticsearch defaults 95 10
/etc/init.d/elasticsearch start
