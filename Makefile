DOCKER_REPO ?= deis/brigade-k8s-gateway
DOCKER_TAG  ?= latest

.PHONY: build
build:
	go build -o bin/k8s-gateway ./cmd/...

# To use docker-build, you need to have Docker installed and configured. You should also set
# DOCKER_REGISTRY to your own personal registry if you are not pushing to the official upstream.
.PHONY: docker-build
docker-build:
	GOOS=linux GOARCH=amd64 go build -o rootfs/k8s-gateway ./cmd/...
	docker build -t "$(DOCKER_REPO):$(DOCKER_TAG)" .

# You must be logged into DOCKER_REGISTRY before you can push.
.PHONY: docker-push
docker-push:
	docker push "$(DOCKER_REPO):$(DOCKER_TAG)"

.PHONY: docker-login
docker-login:
	echo "$(DOCKER_PASSWORD)" | docker login -u "$(DOCKER_USERNAME)" --password-stdin
