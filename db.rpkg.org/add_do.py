#! /usr/bin/env python

import simplejson as json
import sys

if len(sys.argv) != 3:
    print "Usage: " + sys.argv[0] + " <input> <output>\n"
    exit(1)

inp = open(sys.argv[1])
template = json.load(inp)
inp.close()

# Add the DigitalOcean builder
builders = template["builders"]
do = json.loads("""
  {
    "name": "digitalocean",
    "type": "digitalocean",
    "api_key": "{{user `digitalocean_api_key`}}",
    "client_id": "{{user `digitalocean_client_id`}}",
    "image": 5141286,
    "region": 4,
    "size": 66,
    "snapshot_name": "db-rpkg-org-{{timestamp}}",
    "droplet_name": "db-new"
  }
""")
builders.append(do)

# Add two variables needed by the DigitalOcean builder.
# They should be set externally, via a configuration file
# supplied in -var-file or via environment variables
variables = template["variables"]
do_vars = json.loads("""
{ "digitalocean_api_key": "{{env `DIGITALOCEAN_API_KEY`}}",
  "digitalocean_client_id": "{{env `DIGITALOCEAN_CLIENT_ID`}}"
}
""")
template["variables"] = dict(variables.items() + do_vars.items())

# Exclude the DigitalOcean builder from the Vagrant
# post-processor
pp = template["post-processors"][0]
exclude = json.loads("""{ "except": ["digitalocean"] }""")
template["post-processors"][0] = dict(pp.items() + exclude.items())

out=open(sys.argv[2], "w")
json.dump(template, out, indent = 4 * ' ')
out.close()
