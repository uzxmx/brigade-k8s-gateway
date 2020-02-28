DOCKER_REPO ?= deis/brigade-k8s-gateway
DOCKER_TAG  := $(if $(DOCKER_TAG),$(DOCKER_TAG),latest)

ifneq (,$(shell which gsed))
SED := gsed
else
SED := sed
endif

ifeq (,$(shell $(SED) --version 2>/dev/null | sed -n 1p | grep 'GNU sed'))
$(error You must install gnu sed)
endif

.PHONY: build
build:
	GO111MODULE=on go build -o bin/k8s-gateway ./cmd/...

# To use docker-build, you need to have Docker installed and configured. You should also set
# DOCKER_REGISTRY to your own personal registry if you are not pushing to the official upstream.
.PHONY: docker-build
docker-build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -a -o rootfs/k8s-gateway -ldflags '-w -s -extldflags "-static"' ./cmd/...
	docker build -t "$(DOCKER_REPO):$(DOCKER_TAG)" .

# You must be logged into DOCKER_REGISTRY before you can push.
.PHONY: docker-push
docker-push:
	docker push "$(DOCKER_REPO):$(DOCKER_TAG)"

.PHONY: docker-login
docker-login:
	echo "$(DOCKER_PASSWORD)" | docker login -u "$(DOCKER_USERNAME)" --password-stdin

.PHONY: dist
dist:
	mkdir -p dist
	cp -R deploy/helm dist/brigade-k8s-gateway
	[ -n "$(VERSION)" ] && $(SED) -i -Ee 's/^(version:).*$$/\1 $(VERSION)/' dist/brigade-k8s-gateway/Chart.yaml && \
		$(SED) -i -Ee 's/^(tag:).*$$/\1 $(VERSION)/' dist/brigade-k8s-gateway/values.yaml
	(cd dist && tar zcf brigade-k8s-gateway-$(VERSION).tgz brigade-k8s-gateway)

.PHONY: clean
clean:
	rm -rf bin/k8s-gateway rootfs/k8s-gateway dist
