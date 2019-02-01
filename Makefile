#
#	Makefile
#
.PHONY: help build tags push notify-hub-docker-com

help:
	@echo -e "Please use a command: \n \
		make build v=<2.3-debian> dev=true \n \
		make tags $(REPO) \n \
		make push $(REPO) $(USER) $(PW) \n \
		make notify-hub.docker.com TOKEN=<TOKEN> \n \
	"

build:
	@bash .ci/02_build.sh $(v) $(dev)

tags:
	@bash .ci/03_tagging.sh $(REPO)

push:
	@bash .ci/04_push.sh $(REPO) $(USER) $(PW)

notify-hub-docker-com:
	@bash .ci/05_notify_hub.docker.com.sh $(TOKEN)
