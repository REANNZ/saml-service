# frozen_string_literal: true

RSpec.shared_examples 'ETL::Common' do
  def endpoint_json(s, functioning: true)
    {
      location: s.location,
      binding: {
        uri: s.binding
      },
      functioning: functioning
    }
  end

  def indexed_endpoint_json(s, functioning: true)
    {
      location: s.location,
      index: s.index,
      is_default: s.is_default,
      binding: {
        uri: s.binding
      },
      functioning: functioning
    }
  end

  def saml_uri_json(su)
    {
      uri: su.uri
    }
  end

  def contact_json(c)
    {
      id: c.id,
      given_name: c.given_name,
      surname: c.surname,
      email: c.email_address,
      work_phone: c.telephone_number,
      created_at: Time.zone.at(rand(Time.now.utc.to_i))
    }
  end

  def contact_person_json(contact)
    {
      type: {
        name: ContactPerson::TYPE.keys[rand 0..4].to_s
      },
      contact: {
        id: contact.id
      }
    }
  end

  def sirtfi_contact_person_json(contact)
    {
      type: {
        name: 'Security'
      },
      contact: {
        id: contact.id
      }
    }
  end

  # rubocop:disable Metrics/MethodLength
  def key_descriptor_json(kd)
    {
      disabled: kd.disabled,
      type: kd.key_type,
      key_info: {
        certificate: {
          name: kd.key_info.key_name,
          subject: kd.key_info.subject,
          issuer: kd.key_info.issuer,
          data: kd.key_info.data
        }
      }
    }
  end

  def bad_key_descriptor_json
    {
      disabled: false,
      type: :signing,
      key_info: {
        certificate: {
          name: Faker::Lorem.word,
          subject: Faker::Lorem.word,
          issuer: Faker::Lorem.word,
          data: Faker::Lorem.word
        }
      }
    }
  end
  # rubocop:enable Metrics/MethodLength

  def description
    @description ||= "#{Faker::Lorem.sentence}\r\n\t#{Faker::Lorem.sentence}"
  end

  let(:scope) { 'example.edu' }

  let(:contact_instances) do
    create_list(:contact, contact_count)
  end

  let(:sirtfi_contact_instances) do
    create_list(:contact, sirtfi_contact_count)
  end

  let(:contacts_list) do
    [*contact_instances, *sirtfi_contact_instances]
      .map { |ci| contact_json(ci) }
  end

  let(:contacts) { contacts_list }

  shared_examples 'saml_attributes' do
    it 'sets friendly_name' do
      source.each_with_index do |s, i|
        expect(target[i].friendly_name == s[:name])
      end
    end

    it 'sets rest of data' do
      source.each_with_index do |s, i|
        expect({
                 description: target[i].description,
                 oid: target[i].oid,
                 name: target[i].name
               }).to match({
                             description: s[:description],
                             oid: s[:oid],
                             name: "urn:oid:#{s[:oid]}"
                           })
      end
      expect(source.count).to be > 0
      expect(target.count)
        .to eq(source.count)
    end
  end

  shared_examples 'updating a RoleDescriptor' do
    it 're-uses contact instances, updates contacts, updates protocol and key descriptors' do
      expect { run }.to(not_change { Contact.count }.and(
        change { subject.entity_descriptor.reload.contact_people }
      ).and(
        change { subject.entity_descriptor.reload.sirtfi_contact_people }
      ).and(
        change { subject.reload.protocol_supports }
      ).and(
        change { subject.reload.key_descriptors }
      ))
    end
  end

  shared_examples 'updating MDUI content' do
    it 'updates mdui display_names and description' do
      expect { run }.to(change { subject.reload.ui_info.display_names }.and(
                          change { subject.reload.ui_info.descriptions }
                        ))
    end

    it 'squishes incoming description' do
      run
      expect(subject.reload.ui_info.descriptions.first.value)
        .to eq(description.squish)
    end
  end

  shared_examples 'updating an SSODescriptor' do
    include_examples 'updating a RoleDescriptor'

    it 'updates name id formats, artifact resolutions and single_logout services' do
      expect { run }.to(change { subject.reload.name_id_formats }.and(
        change { subject.reload.artifact_resolution_services }
      ).and(
        change { subject.reload.single_logout_services }
      ).and(
        change { subject.reload.manage_name_id_services }
      ))
    end
  end
end
