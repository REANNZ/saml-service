#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../config/environment'
require 'thor'

# rubocop:disable Metrics/ClassLength
class ConfigureCLI < Thor
  desc 'fr_source [options...]', 'Create or update a Federation Registry source'
  option :source_tag,
         desc: 'Unique tag to apply to all entities resolved from FR'
  option :hostname, desc: 'The hostname of the Federation Registry instance'
  option :secret, desc: 'The export secret configured in Federation Registry'
  option :registration_authority,
         desc: 'The URI for MDRPI::RegistrationInfo/@registrationAuthority'
  option :registration_policy,
         desc: 'The URI for MDRPI::RegistrationInfo/RegistrationPolicy'
  option :lang, desc: 'The specified language for any localised elements'
  long_desc <<-LONGDESC
    Configures the SAML Service to sync to an upstream Federation Registry using
    the Export API.

    The provided secret will be used to authenticate against the Export API.
  LONGDESC

  def fr_source
    source, other = FederationRegistrySource.all
    raise('Multiple FederationRegistrySource objects exist') if other

    source ||= new_federation_registry_source(options[:source_tag])

    update_registration_info(source)
    source.update(options.symbolize_keys.slice(:hostname, :secret))
  end

  desc 'raw_entity_source [options...]', 'Create or update a source of entities
  from a remotely published SAML 2.0 compliant metadata document'
  option :source_tag,
         desc: 'Unique tag to apply to all entities resolved from this source'
  option :rank, desc: 'How this source should be considered in relation to other
  EntitySources. Should the same EntityID exist in multiple EntitySource, the
  source with the lowest numeric rank shall be used. Unique per SAML service
  instance.'
  option :url, desc: 'The URL of SAML metadata document to download'
  option :cert, desc: 'A local file containing the metadata sources validation
  certificate. The validity of this certificate should have previously been
  proven out of band e.g. sha256hash compare.'

  long_desc <<-LONGDESC
    Configures the SAML Service to sync to an existing upstream SAML metadata
    source, representing entities internally as RawEntityDescriptors for further
    processing and mixing into local metadata feeds.

    The provided certificate will be used to validate that the metadata source
    being acquired was validly signed and published by the expected originator
    (i.e. a 3rd party federation).
  LONGDESC

  def raw_entity_source
    source =
      EntitySource.find_or_create(source_tag: options[:source_tag]) do |e|
        e.rank = options[:rank]
        e.enabled = true
      end

    source.update(url: options[:url], certificate: load_certificate)
  end

  desc 'keypair [options...]', 'Create or update a Keypair for metadata signing'
  option :cert, desc: 'The file containing the self-signed certificate'
  option :key, desc: 'The file containing the private key'
  long_desc <<-LONGDESC
    Configures the SAML Service with a keypair which can be used by a metadata
    instance to sign a generated document.

    An existing keypair will be left unmodified. Keypairs are identified by
    the certificate's SHA1 fingerprint.
  LONGDESC

  def keypair
    cert, key = load_keypair
    fingerprint = sha1_fingerprint(cert)
    return if Keypair.first_where(fingerprint: fingerprint)

    Keypair.create(certificate: cert.to_pem, key: key.to_pem,
                   fingerprint: fingerprint)
  end

  desc 'md_instance [options...]', 'Create or update a Metadata Instance'
  option :cert, desc: 'The file containing the metadata certificate'
  option :name, desc: 'The <EntitesDescriptor> name included in the XML'
  option :identifier, desc: 'The identifier for the metadata instance'
  option :tag, desc: 'The primary tag for the metadata instance'
  option :hash, desc: 'The hash algorithm for signing (default: SHA256)',
                default: 'SHA256'
  option :publisher, desc: 'The URI for MDRPI::PublicationInfo/@publisher'
  option :lang, desc: 'The specified language for any localised elements'
  long_desc <<-LONGDESC
    Configures the SAML Service with a metadata instance which will be used to
    generate an output metadata document.

    The primary tag for the created metadata instance will be taken from the
    `tag` option. The provided certificate must have a corresponding `keypair`
    entry already registered.

    Only one metadata instance can be created for each primary tag - any prior
    instance with the same tag will be updated with new configuration.
  LONGDESC
  def md_instance
    instance = MetadataInstance.find_or_new(identifier: options[:identifier])
    instance.update(md_instance_attrs)

    update_publication_info(instance)
  end

  private

  def new_federation_registry_source(source_tag)
    FederationRegistrySource.new do |source|
      source.entity_source = EntitySource.create(enabled: true,
                                                 rank: 10,
                                                 source_tag: source_tag)
    end
  end

  def update_registration_info(source)
    source.registration_authority = options[:registration_authority]
    source.registration_policy_uri = options[:registration_policy]
    source.registration_policy_uri_lang = options[:lang]
  end

  def load_keypair
    [load_certificate, OpenSSL::PKey::RSA.new(File.read(options[:key]))]
  end

  def load_certificate
    OpenSSL::X509::Certificate.new(File.read(options[:cert]))
  end

  def sha1_fingerprint(cert)
    OpenSSL::Digest::SHA1.new(cert.to_der).to_s.downcase
  end

  def md_instance_attrs
    opts = options
    fingerprint = sha1_fingerprint(load_certificate)
    keypair = Keypair.first_where(fingerprint: fingerprint)

    keypair || raise('The provided certificate has not been registered')

    { name: opts[:name], federation_identifier: opts[:tag],
      primary_tag: opts[:tag], hash_algorithm: opts[:hash].downcase,
      validity_period: 7.days, cache_period: 6.hours,
      keypair_id: keypair.id, all_entities: true }
  end

  def update_publication_info(instance)
    pi = instance.publication_info || MDRPI::PublicationInfo.new
    pi.update(publisher: options[:publisher], metadata_instance_id: instance.id)
  end
end
# rubocop:enable Metrics/ClassLength

ConfigureCLI.start(ARGV) if $PROGRAM_NAME == __FILE__
