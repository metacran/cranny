
UBUNTU=ubuntu1404
DOBUILD=packer build -only=digitalocean template.json

all:

.PHONY: all
	 db-common db-vagrant db-do db-extra-files

# -------------------------------------------------------------------

DB=db.rpkg.org

db-common: $(DB)/template.json db-extra-files

$(DB)/template.json: box-ubuntu/$(UBUNTU).json
	cp $< $@
	$(DB)/add_couchdb.py $@ $@ || rm $@
	$(DB)/add_do.py $@ $@ || rm $@

db-extra-files:
	cp -r box-ubuntu/{http,script} ${DB}/
	cat $(DB)/script/no-vagrant.sh box-ubuntu/script/vagrant.sh \
		> $(DB)/script/vagrant.sh

db-vagrant: db-common $(DB)/box/virtualbox/$(UBUNTU)-nocm.box

db-do:db-common
	. config.sh && cd $(DB) && $(DOBUILD)

$(DB)/box/virtualbox/$(UBUNTU)-nocm.box: $(DB)/template.json
	. config.sh && cd $(DB) && packer build -only=virtualbox-iso \
		template.json

# -------------------------------------------------------------------

SEER=seer.rpkg.org

seer-common: $(SEER)/template.json seer-extra-files

$(SEER)/template.json: box-ubuntu/$(UBUNTU).json
	cp $< $@
	$(SEER)/add_es.py $@ $@ || rm $@
	$(SEER)/add_do.py $@ $@ || rm $@

seer-extra-files:
	cp -r box-ubuntu/{http,script} ${SEER}/
	cat $(SEER)/script/no-vagrant.sh box-ubuntu/script/vagrant.sh \
		> $(SEER)/script/vagrant.sh

seer-vagrant: seer-common $(SEER)/box/virtualbox/$(UBUNTU)-nocm.box

seer-do: seer-common
	. config.sh && cd $(SEER) && $(DOBUILD)

$(SEER)/box/virtualbox/$(UBUNTU)-nocm.box: $(SEER)/template.json
	. config.sh && cd $(SEER) && packer build -only=virtualbox-iso \
		template.json
