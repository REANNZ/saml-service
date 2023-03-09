ARG BASE_IMAGE=""
FROM $BASE_IMAGE as base

COPY .FORCE_NEW_DOCKER_BUILD .FORCE_NEW_DOCKER_BUILD
USER app

RUN mkdir -p ./public/assets \
	sockets \
	tmp/pids
USER root

EXPOSE 3000
ENTRYPOINT [ "/app/bin/boot.sh" ]
CMD [ "bundle exec puma"]

FROM base as dependencies

RUN yum -y update \
	&& yum -y install epel-release \
	&& yum install -y \
	--enablerepo=devel \
	libtool \
	make \
	xz \
	which \
	cmake \
	mysql \
	mysql-devel \
	automake \
	&& yum -y clean all \
	&& rm -rf /var/cache/yum

USER app

COPY --chown=app ./Gemfile ./Gemfile.lock ./

## is installing production gems
RUN bundle install \
	&& rbenv rehash

COPY --chown=app ./Rakefile ./
COPY --chown=app config ./config
COPY --chown=app schema ./schema
COPY --chown=app lib/tasks/xsd.rake ./lib/tasks/xsd.rake

RUN bundle exec rake xsd:all

FROM dependencies as development
ARG LOCAL_BUILD=false
ENV RAILS_ENV development

USER root

RUN bundle config set --local without "non_docker"

RUN [ "${LOCAL_BUILD}" == "true" ] && bundle config set --local force_ruby_platform true || echo "not local"

USER app

RUN bundle install \
	&& rbenv rehash

COPY --chown=app . .

ARG RELEASE_VERSION="VERSION_PROVIDED_ON_BUILD"
ENV RELEASE_VERSION $RELEASE_VERSION

FROM base as production

ENV RAILS_ENV production
COPY --from=dependencies /usr/bin/which /usr/bin/mysql /usr/bin/
COPY --from=dependencies /opt/.rbenv /opt/.rbenv
COPY --from=dependencies /usr/local/bundle /usr/local/bundle
COPY --from=dependencies ${APP_DIR}/schema ${APP_DIR}/schema
COPY --from=dependencies /usr/lib64/mysql /usr/lib64/mysql

COPY --chown=app . .

RUN rm -rf spec \
	node_modules \
	.yarn \
	.cache \
	/usr/local/bundle/cache/*.gem \
	tmp/cache \
	vendor/assets \
	lib/assets

USER app

ARG RELEASE_VERSION="VERSION_PROVIDED_ON_BUILD"
ENV RELEASE_VERSION $RELEASE_VERSION
