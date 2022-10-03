#!/bin/bash

set -e

if [ "${DEBUG_CONTAINER-}" == "true" ]; then
  echo 'Debugging!'
  tail -f /dev/null
else
  echo "Preparing database..."
  if [ "${RAILS_ENV-}" != "production" ]; then
    bundle exec rake db:create
  fi
  bundle exec rake db:migrate
fi
