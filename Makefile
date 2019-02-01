#
#	Makefile
#
.PHONY: help test-travis build tags push install notify-hub-docker-com

help:
	@echo -e "Please use a command: \n \
		make before_install \n \
		make build v=<2.3-debian> dev=true \n \
		make tags \n \
		make push \n \
		make notify-hub.docker.com TOKEN=<TOKEN> \n \
	"


before_install:
	.ci/01_before_install.sh

build:
	.ci/02_build.sh $(v) $(dev)

tags:
	.ci/03_tagging.sh

push:
	.ci/04_push.sh

notify-hub-docker-com:
	.ci/05_notify_hub.docker.com.sh $(TOKEN)
