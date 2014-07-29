
UBUNTU=ubuntu1404
DB=db.rpkg.org

all:

db-common: $(DB)/template.json db-extra-files

$(DB)/template.json: box-ubuntu/$(UBUNTU).json
	cp $< $@
	$(DB)/add_couchdb.py $@ $@ || rm $@
	$(DB)/add_do.py $@ $@ || rm $@

db-extra-files:
	cp -r box-ubuntu/{http,script} ${DB}/
	cat $(DB)/script/no-vagrant.sh box-ubuntu/script/vagrant.sh \
		> $(DB)/script/vagrant.sh

db-vagrant: $(DB)/box/virtualbox/$(UBUNTU)-nocm.box

db-do:
	cd $(DB) && packer build -only=digitalocean \
		-var-file=../config.json template.json

$(DB)/box/virtualbox/$(UBUNTU)-nocm.box: $(DB)/template.json
	cd $(DB) && packer build -only=virtualbox-iso \
		-var-file=../config.json template.json

.PHONY: all
	 db-common db-vagrant db-do db-extra-files
