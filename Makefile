-include .env

LOCAL_IP=$(shell ipconfig getifaddr en0)
PWD=$(shell pwd)
docker-login:
	@if [ "${DOCKER_ECR}" != "" ]; then \
		aws-vault exec shared_services -- aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin ${DOCKER_ECR}; \
	fi
BUILD_TARGET=--target development

build-image:
	make docker-login
	docker build .  -t  saml-service \
	${BUILD_TARGET} --build-arg DOCKER_ECR=${DOCKER_ECR}

## use this to connect to a running container
connect-image:
	docker container exec -it  saml-service /bin/bash
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
	saml-service 

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
	 saml-service
	 
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
	--name  saml-service  saml-service "rspec -fd ${FILE}"
