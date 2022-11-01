ARG DOCKER_ECR=""
FROM ${DOCKER_ECR}ruby-base-image:2.7 as ruby
FROM ruby as saml-service

ENV APP_DIR=/app

WORKDIR ${APP_DIR}

RUN mkdir -p ./public/assets \
	&& mkdir sockets \
	&& mkdir tmp \
	&& mkdir tmp/pids \
	&& gem install bundler

# Install development tools so that the gems can be built
# Once the gems are installed, the tools are purged as they are no longer required
RUN apt-get install -y --no-install-recommends \
	build-essential \
	mariadb-client \
	apt-utils \
	unzip \
	cmake \
	pkg-config

# Copy only the files required to run bundle install.
# The bundle install layer below will be cached unless these files change
COPY Gemfile Gemfile.lock ./

RUN bundle install \
	&& apt-get purge -y --auto-remove \
	build-essential \
	apt-utils \
	git \
	libpq-dev \
	gnupg \
	cmake \
	pkg-config \ 
	unzip && apt-get clean

COPY . .

RUN bundle exec rake xsd:all

RUN groupadd -g 501 app \
	&& useradd -u 501 -g 501 -ms /bin/bash app \
	&& chown -R app ${APP_DIR} /var/run/

USER app

EXPOSE 3000
ARG RELEASE_VERSION="VERSION_PROVIDED_ON_BUILD"
ENV RELEASE_VERSION $RELEASE_VERSION
ENTRYPOINT [ "/app/bin/boot.sh" ]
CMD [ "puma"]
FROM saml-service as development

ENV RAILS_ENV development
# Use gems & NPMs from image by default but allow user to change dynamically
VOLUME /usr/local/bundle

FROM saml-service as production

ENV RAILS_ENV production
RUN rm -rf spec
RUN bundle config set --local without "development test" && bundle install
