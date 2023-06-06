# frozen_string_literal: true

FactoryBot.define do
  test_rsa_keys = {}

  factory :rsa_key, class: OpenSSL::PKey::RSA do
    transient { bits { 2048 } }

    initialize_with do
      test_rsa_keys[bits.to_i] ||= OpenSSL::PKey::RSA.new(bits)
    end

    skip_create
  end

  factory :certificate, class: OpenSSL::X509::Certificate do
    transient do
      rsa_key { create(:rsa_key) }
      subject_dn { "CN=#{SecureRandom.urlsafe_base64}" }
      issuer_dn { subject_dn }
      digest_class { OpenSSL::Digest::SHA256 }
    end

    public_key { rsa_key.public_key }
    issuer { OpenSSL::X509::Name.parse(issuer_dn) }
    subject { OpenSSL::X509::Name.parse(subject_dn) }

    not_before { Time.zone.now }
    not_after { 1.hour.from_now }
    serial { 0 }
    version { 2 }

    after(:build) do |cert, attr|
      cert.sign(attr.rsa_key, attr.digest_class.new)
    end

    skip_create
  end

  factory :keypair do
    transient do
      rsa_key { create(:rsa_key) }
      x509_certificate { create(:certificate, rsa_key:) }
    end

    fingerprint do
      OpenSSL::Digest::SHA1.new(x509_certificate.to_der).to_s.downcase
    end

    certificate { x509_certificate.to_pem }
    key { rsa_key.to_pem }
  end
end
