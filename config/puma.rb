# frozen_string_literal: true

require 'yaml'

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.

config = YAML.load_file(File.expand_path('deploy.yml', __dir__))
puma_config = config['puma']

threads 1, 1

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
bind ENV.fetch('PORT', puma_config['bind'])

# Specifies the `environment` that Puma will run in.
environment ENV.fetch('RAILS_ENV', 'development')

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch('PIDFILE', 'tmp/pids/puma.pid')

# Specifies the `worker_timeout` threshold that Puma will use to wait before
# terminating a worker in development environments.
worker_timeout 3600 if ENV.fetch('RAILS_ENV', 'development') == 'development'

# Ensure persistent timeout is greater than ALB, see
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#connection-idle-timeout
persistent_timeout 75

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers ENV.fetch('WEB_CONCURRENCY', 3)

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

stdout_redirect puma_config['stdout'],
                puma_config['stderr'],
                :append
tag 'saml'
