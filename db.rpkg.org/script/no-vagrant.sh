#! /bin/bash

if [ "$PACKER_BUILDER_TYPE" == "digitalocean" ]; then
    exit 0
fi
