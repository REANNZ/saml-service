# frozen_string_literal: true

Sentry.init do |config|
  config.send_default_pii = true
  config.enabled_environments = [Rails.application.config.saml_service[:url_options][:base_url]]
  config.environment = Rails.application.config.saml_service[:url_options][:base_url]
  config.release = Rails.application.config.saml_service[:version]
  config.logger = Logger.new(ENV.fetch('STDOUT', $stdout))
  config.logger.level = Logger::WARN
  config.include_local_variables = true

  # Puma raises this error when a client makes a malformed HTTP request. It responds appropriately with 400 Bad Request.
  # We don't need to hear about that!
  # See https://github.com/getsentry/sentry-ruby/pull/2026#issuecomment-1525031744.
  config.excluded_exceptions << 'Puma::HttpParserError'

  config.traces_sampler = lambda do |sampling_context|
    transaction_context = sampling_context[:transaction_context]
    op = transaction_context[:op]
    transaction_name = transaction_context[:name]

    # If this is the continuation of a trace, just use that decision (rate controlled by the caller)
    return sampling_context[:parent_sampled] unless sampling_context[:parent_sampled].nil?

    # If this is a Crawler/Bot or a health check we don't want to know about the transaction
    # Last confirmed correct regex for AWS health check UA on 28/7/2021
    ua = Sentry.get_current_scope.rack_env['HTTP_USER_AGENT']
    return 0.0 if ua && (CrawlerDetect.is_crawler?(ua) || ua.match?(/^Amazon-Route53-Health-Check-Service/))

    case op
    when /request/
      # for Rails applications, transaction_name would be
      # the request's path (env["PATH_INFO"]) instead of "Controller#action"
      case transaction_name
      when /health/
        return 0.0
      end
    end
    # For everything else take a smaller sample size as
    # we're on a smaller plan and don't want to consume all resources
    # This number likely needs to be debated and modified over time as needs/plans change
    0.2
  end
end
