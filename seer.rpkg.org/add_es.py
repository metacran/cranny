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
scripts.insert(cleanup, 'script/es.sh')
scripts.insert(cleanup, 'script/hostname.sh')

# Ass ES password as an environment variable
variables = template["variables"]
do_vars = json.loads("""
{ 
  "es_password": "{{env `ES_PASSWORD`}}",
  "es_hostname": "{{env `ES_HOSTNAME`}}"
}
""")
template["variables"] = dict(variables.items() + do_vars.items())

envvars = template["provisioners"][0]["environment_vars"]
c_pw = json.loads(""" "ES_PASSWORD={{user `es_password`}}" """)
c_hn = json.loads(""" "HOSTNAME={{user `es_hostname`}}" """)
envvars.append(c_pw)
envvars.append(c_hn)

out=open(sys.argv[2], "w")
json.dump(template, out, indent = 4 * ' ')
out.close()
