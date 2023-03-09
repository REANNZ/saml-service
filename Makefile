-include .env

LOCAL_IP=$(shell ipconfig getifaddr en0)
PWD=$(shell pwd)
docker-login:
	@if [ "${DOCKER_ECR}" != "" ]; then \
		aws-vault exec shared_services -- aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin ${DOCKER_ECR}; \
	fi
BUILD_TARGET=development
version := $(shell cat .ruby-version)
BASE_IMAGE="${DOCKER_ECR}ruby-base:${version}"

build-image: docker-login
	docker build .  -t  saml-service:${BUILD_TARGET} \
	--build-arg LOCAL_BUILD=true \
	--build-arg BASE_IMAGE=${BASE_IMAGE} \
	--target ${BUILD_TARGET}

## use this to connect to a running container
connect-image:
	docker container exec -it  saml-service:${BUILD_TARGET} /bin/bash
#curl 127.0.0.1:3000 > html.test
COMMAND=/bin/bash
run-image-bash:
	docker run -it --rm --name saml-service \
	--entrypoint ${COMMAND} \
	--env-file=.env \
	-e SAML_DB_HOST=${LOCAL_IP} \
	-v ${PWD}/app:/app/app \
	-v ${PWD}/config:/app/config \
	-v ${PWD}/lib:/app/lib \
	-v ${PWD}/log:/app/log \
	-v ${PWD}/db:/app/db \
	saml-service:${BUILD_TARGET}

remove-all-containers:
	docker rm $(docker ps -a -q)

run-image:
	docker run --rm -p 3000:3000 --name  saml-service --env-file=.env \
	-v ${PWD}/app:/app/app \
	-v ${PWD}/config:/app/config \
	-v ${PWD}/lib:/app/lib \
	-v ${PWD}/log:/app/log \
	-v ${PWD}/db:/app/db \
	-e SAML_DB_HOST=${LOCAL_IP} \
	 saml-service:${BUILD_TARGET}

FILE=
run-image-tests:
	docker run -it --rm --env-file=.env.test \
	-v ${PWD}/app:/app/app \
	-v ${PWD}/config:/app/config \
	-v ${PWD}/coverage:/app/coverage \
	-v ${PWD}/tmp/capybara:/app/tmp/capybara \
	-v ${PWD}/lib:/app/lib \
	-v ${PWD}/spec:/app/spec \
	-v ${PWD}/log:/app/log \
	-v ${PWD}/db:/app/db \
	-e SAML_DB_HOST=${LOCAL_IP} \
	--name  saml-service:${BUILD_TARGET}  saml-service "rspec -fd ${FILE}"
