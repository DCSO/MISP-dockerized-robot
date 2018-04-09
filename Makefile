#
#	Makefile for robot
#
CONTAINER := robot
LATEST_VERSION := 1.0.0
LATEST_BASE := ubuntu
BASE := ubuntu
VERSION :=1.0.0

CMDSEP := &
PUBLIC_REPO := dcso/misp-$(CONTAINER)
PRIVATE_REPO := dcso/misp-$(CONTAINER)-private
REPOS := $(PUBLIC_REPO) $(PRIVATE_REPO)

test:
	#- ~/misp-docs/official-images/test/run.sh "dcso/misp-${CONTAINER}:$VERSION-${BASE}"
	true

test-travis:
	.travis/travis-cli.sh check

build-travis:
	.travis/build.sh $(v)-$(b)

build:
	$(foreach b, $(BASE), \
		$(foreach v, $(VERSION), \
			.travis/build.sh $(v)-$(b) $(CMDSEP) \
		) \
	)
		docker images|grep $(CONTAINER)

tags:
	$(foreach i, $(REPOS), \
		$(foreach v, $(VERSION), docker tag $(i):$(v)-$(LATEST_BASE) $(i):$(v);) \
		docker tag $(i):$(LATEST_VERSION)-$(LATEST_BASE) $(i):latest; ) 
		docker images|grep $(CONTAINER)

tags-travis:
ifeq ($(b),$(LATEST_BASE)) 
	$(foreach i, $(REPOS), docker tag $(i):$(v)-$(LATEST_BASE) $(i):$(v);)
endif

ifeq ($(v)$(b),$(LATEST_VERSION)$(LATEST_BASE)) 
	$(foreach i, $(REPOS), echo $(i); docker tag $(i):$(LATEST_VERSION)-$(LATEST_BASE) $(i):latest;)
endif

push-image:
ifeq ($(LOCATION),public)
	docker push $(PUBLIC_REPO)
else ifeq ($(LOCATION),private)
	docker push $(PRIVATE_REPO)
endif

.PHONY: build build-travis push-image test test-travis tags tags-travis