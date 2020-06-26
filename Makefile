.PHONY: docker-build docker-push

docker-build:
	@docker build \
	--no-cache \
	--tag cmacrae/lgtm:$(strip $(shell git rev-parse --short HEAD)) \
	--tag cmacrae/lgtm:0.1.0 \
	--tag cmacrae/lgtm:latest .

docker-push: docker-build
	@docker push cmacrae/lgtm:$(strip $(shell git rev-parse --short HEAD))
	@docker push cmacrae/lgtm:0.1.0
	@docker push cmacrae/lgtm:latest
