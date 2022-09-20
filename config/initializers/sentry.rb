# frozen_string_literal: true

Sentry.init do |config|
  config.send_default_pii = true

  config.enabled_environments = [Rails.application.config.saml_service[:url_options][:base_url]]
  config.environment = Rails.application.config.saml_service[:url_options][:base_url]
  config.release = Rails.application.config.saml_service[:version]

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
    return 0.0 if op == '/request/' && transaction_name == '/health/'

    # For everything else take a smaller sample size as we're on a smaller plan and don't want to consume all resources
    # This number likely needs to be debated and modified over time as needs/plans change
    0.2
  end
end
