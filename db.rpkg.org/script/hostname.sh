#! /bin/bash -exu

if [ "$PACKER_BUILDER_TYPE" != "digitalocean" ]; then
    exit 0
fi

hostname "$HOSTNAME"
echo "$HOSTNAME" > /etc/hostname
sed 's/^127.0.0.1\tubuntu.*$/127.0.0.1\t'$HOSTNAME'/' \
    /etc/hosts >/tmp/hosts && cp /tmp/hosts /etc/hosts
