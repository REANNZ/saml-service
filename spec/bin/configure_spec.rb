# frozen_string_literal: true

require 'rails_helper'
require_relative '../../bin/configure'

RSpec.describe ConfigureCLI do
  describe '#fr_source' do
    let(:hostname) { Faker::Internet.domain_name }
    let(:secret) { SecureRandom.urlsafe_base64 }
    let(:registration_authority) { Faker::Internet.domain_name }
    let(:registration_policy) { Faker::Internet.domain_name }
    let(:lang) { Faker::Lorem.word }
    let(:source_tag) { Faker::Lorem.words.join('-') }

    def run(**overrides)
      args = overrides.reverse_merge(
        hostname: hostname,
        secret: secret,
        registration_authority: registration_authority,
        registration_policy: registration_policy,
        lang: lang,
        source_tag: source_tag
      ).transform_keys { |sym| "--#{sym.to_s.dasherize}" }.to_a.flatten

      ConfigureCLI.start(['fr_source', *args])
    end

    context 'when multiple sources exist' do
      let!(:fr_sources) { create_list(:federation_registry_source, 2) }

      it 'raises an error' do
        expect { run }
          .to raise_error('Multiple FederationRegistrySource objects exist')
      end
    end

    context 'when a source exists' do
      let!(:fr_source) { create(:federation_registry_source) }

      it 'updates the secret' do
        new_secret = SecureRandom.urlsafe_base64
        expect { run(secret: new_secret) }
          .to change { fr_source.reload.secret }.to(new_secret)
      end

      it 'updates the hostname' do
        new_hostname = "manager.#{Faker::Internet.domain_name}"
        expect { run(hostname: new_hostname) }
          .to change { fr_source.reload.hostname }.to(new_hostname)
      end

      it 'updates the registration authority' do
        new_registration_authority = Faker::Internet.url
        expect { run(registration_authority: new_registration_authority) }
          .to change { fr_source.reload.registration_authority }
          .to(new_registration_authority)
      end

      it 'updates the registration policy' do
        new_registration_policy = Faker::Internet.url
        expect { run(registration_policy: new_registration_policy) }
          .to change { fr_source.reload.registration_policy_uri }
          .to(new_registration_policy)
      end
    end

    context 'when no source exists' do
      it 'creates a new source' do
        expect { run }
          .to change(FederationRegistrySource, :count).by(1)
      end

      it 'creates an enabled EntitySource' do
        expect { run }
          .to change(EntitySource, :count).by(1)

        expect(EntitySource.last)
          .to have_attributes(enabled: true, rank: 10, source_tag: source_tag)
      end

      it 'sets the correct registration attributes on the new source' do
        run
        expected = {
          registration_authority: registration_authority,
          registration_policy_uri: registration_policy,
          registration_policy_uri_lang: lang
        }
        expect(FederationRegistrySource.last).to have_attributes(expected)
      end
    end
  end

  describe '#keypair' do
    let(:cert_file) { '/nonexistent/path/to/cert.pem' }
    let(:key_file) { '/nonexistent/path/to/key.pem' }

    let(:rsa_key) { create(:rsa_key) }
    let(:x509_certificate) { create(:certificate, rsa_key: rsa_key) }

    before do
      allow(File).to receive(:read).with(cert_file)
                                   .and_return(x509_certificate.to_pem)
      allow(File).to receive(:read).with(key_file).and_return(rsa_key.to_pem)
    end

    def run
      ConfigureCLI.start(['keypair',
                          '--cert', cert_file,
                          '--key', key_file])
    end

    context 'when the keypair exists' do
      let!(:keypair) do
        create(:keypair, x509_certificate: x509_certificate, rsa_key: rsa_key)
      end

      it 'creates no new keypair' do
        expect { run }.not_to change(Keypair, :count)
      end

      it 'does not change the existing keypair' do
        expect { run }.not_to(change { keypair.reload.to_hash })
      end
    end

    context 'when no keypair exists' do
      it 'creates a keypair' do
        expect { run }.to change(Keypair, :count).by(1)

        expected = { certificate: x509_certificate.to_pem, key: rsa_key.to_pem }
        expect(Keypair.last).to have_attributes(expected)
      end
    end
  end

  describe '#md_instance' do
    let(:hash) { nil }
    let(:name) { "#{Faker::Lorem.word}.#{Faker::Internet.domain_name}" }
    let(:tag) { Faker::Lorem.word }
    let(:identifier) { SecureRandom.urlsafe_base64 }
    let(:publisher) { Faker::Internet.url }
    let(:lang) { 'en' }
    let!(:keypair) { create(:keypair) }

    let(:cert_file) { '/nonexistent/path/to/cert.pem' }

    before do
      allow(File).to receive(:read).with(cert_file)
                                   .and_return(keypair.certificate)
    end

    def run
      args = ['md_instance',
              '--cert', cert_file,
              '--name', name,
              '--identifier', identifier,
              '--tag', tag,
              '--publisher', publisher,
              '--lang', lang]

      args += ['--hash', hash] if hash

      ConfigureCLI.start(args)
    end

    context 'when the metadata instance exists' do
      let!(:instance) { create(:metadata_instance, identifier: identifier) }

      it 'does not create a new metadata instance' do
        expect { run }.not_to change(MetadataInstance, :count)
      end

      it 'updates the attributes' do
        attrs = { keypair_id: keypair.id, name: name, hash_algorithm: 'sha256' }
        expect { run }.to change { instance.reload.to_hash }.to include(attrs)
      end

      it 'does not create a new PublicationInfo' do
        expect { run }.to not_change(MDRPI::PublicationInfo, :count)
          .and not_change(MDRPI::UsagePolicy, :count)
      end

      it 'updates the PublicationInfo' do
        pi = instance.publication_info

        run

        expect { pi.reload }.to change { pi.values }
          .to include(publisher: publisher)
      end
    end

    context 'when no metadata instance exists' do
      it 'creates a valid metadata instance' do
        expect { run }.to change(MetadataInstance, :count).by(1)

        expect(MetadataInstance.last).to be_valid
          .and have_attributes(keypair_id: keypair.id, name: name)
      end

      it 'creates a valid PublicationInfo' do
        expect { run }.to change(MDRPI::PublicationInfo, :count)
          .by(1)

        md_instance = MetadataInstance.last

        expect(md_instance.publication_info)
          .to have_attributes(publisher: publisher)
      end
    end

    context 'when the keypair is missing' do
      before { keypair.destroy }

      it 'raises an informative error' do
        expect { run }.to raise_error(/certificate has not been registered/)
      end
    end

    context 'when the hash is provided' do
      let(:hash) { 'sha1' }

      it 'uses the provided hash' do
        run
        expect(MetadataInstance.last).to have_attributes(hash_algorithm: hash)
      end
    end
  end

  describe '#raw_entity_source' do
    let(:rank) { Faker::Number.number(digits: 2).to_i }
    let(:url) { Faker::Internet.url }
    let(:cert_path) { Rails.root.join('spec', 'tmp', 'res_cert.pem') }
    let(:rsa_key) { create(:rsa_key) }
    let(:x509_certificate) { create(:certificate, rsa_key: rsa_key) }
    let(:source_tag) { Faker::Lorem.words.join('-') }

    before do
      File.write(cert_path, x509_certificate)
    end

    after do
      File.delete(cert_path)
    end

    def run(**overrides)
      args = overrides.reverse_merge(
        rank: rank,
        url: url,
        cert: cert_path,
        source_tag: source_tag
      ).transform_keys { |sym| "--#{sym.to_s.dasherize}" }.to_a.flatten

      ConfigureCLI.start(['raw_entity_source', *args])
    end

    context 'when a source exists' do
      let(:cert_path2) { Rails.root.join('spec', 'tmp', 'res_cert_new.pem') }
      let(:rsa_key2) { create(:rsa_key) }
      let(:x509_certificate2) { create(:certificate, rsa_key: rsa_key) }
      let!(:source) do
        create(:entity_source, rank: rank, certificate: x509_certificate,
                               source_tag: source_tag)
      end

      before do
        File.write(cert_path2, x509_certificate2)
      end

      after do
        File.delete(cert_path2)
      end

      it 'updates the URL' do
        new_url = Faker::Internet.url
        expect { run(url: new_url) }.to change { source.reload.url }.to(new_url)
      end

      it 'updates the certificate' do
        expect { run(cert: cert_path2) }
          .to change { source.reload.certificate }.to(x509_certificate2.to_pem)
      end
    end

    context 'when no source exists' do
      it 'creates a new source' do
        expect { run }
          .to change(EntitySource, :count).by(1)
      end

      it 'creates the expected EntitySource' do
        run
        expect(EntitySource.last)
          .to have_attributes(enabled: true, rank: rank,
                              url: url, certificate: x509_certificate.to_pem,
                              source_tag: source_tag)
      end
    end
  end
end
