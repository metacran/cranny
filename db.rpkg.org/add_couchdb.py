#! /usr/bin/env python

import simplejson as json
import sys

if len(sys.argv) != 3:
    print "Usage: " + sys.argv[0] + " <input> <output>\n"
    exit(1)

inp = open(sys.argv[1])
template = json.load(inp)
inp.close()

# Add provisioner before 'minimize.sh'. 
scripts = template['provisioners'][0]['scripts']
cleanup = scripts.index('script/minimize.sh')
scripts.insert(cleanup, 'script/secure.sh')
scripts.insert(cleanup, 'script/couchdb.sh')
scripts.insert(cleanup, 'script/hostname.sh')

# Add couchdb password as an environment variable
variables = template["variables"]
do_vars = json.loads("""
{ 
  "couchdb_password": "{{env `COUCHDB_PASSWORD`}}",
  "couchdb_hostname": "{{env `COUCHDB_HOSTNAME`}}"
}
""")
template["variables"] = dict(variables.items() + do_vars.items())

envvars = template["provisioners"][0]["environment_vars"]
c_pw = json.loads(""" "COUCHDB_PASSWORD={{user `couchdb_password`}}" """)
c_hn = json.loads(""" "HOSTNAME={{user `couchdb_hostname`}}" """)
envvars.append(c_pw)
envvars.append(c_hn)

out=open(sys.argv[2], "w")
json.dump(template, out, indent = 4 * ' ')
out.close()
