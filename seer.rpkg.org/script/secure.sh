#! /bin/bash -exu

ufw allow ssh
ufw allow 9200
ufw --force enable
ufw reload
