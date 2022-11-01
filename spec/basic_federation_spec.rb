# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BasicFederation' do
  def run
    create :basic_federation
  end

  it 'creates 5 EntityDescriptor, 2 IDPSSODescriptor, 3 AttributeAuthorityDescriptor,' \
     ' 2 SPSSODescriptor and 1 EntitySource' do
    expect { run }.to change(EntitySource, :count).by(1).and(
      change(EntityDescriptor, :count).by(5)
    ).and(
      change(IDPSSODescriptor, :count).by(2)
    ).and(
      change(AttributeAuthorityDescriptor, :count).by(3)
    ).and(
      change(SPSSODescriptor, :count).by(2)
    )
  end

  before :all do
    @entity_source = run
  end

  context 'RoleDescriptors' do
    subject do
      @entity_source.known_entities
                    .map(&:entity_descriptor).flat_map(&:role_descriptors)
    end

    it 'has protocol supports and key descriptors' do
      subject.each do |rd|
        expect(rd.protocol_supports).not_to be_empty
        rd.key_descriptors.each do |kd|
          expect(kd.key_info.data).not_to be_empty
        end
      end
    end
  end

  context 'IDPSSODescriptors' do
    subject do
      @entity_source.known_entities
                    .map(&:entity_descriptor).flat_map(&:idp_sso_descriptors)
    end

    it 'has single sign on service' do
      subject.each { |idp| expect(idp.single_sign_on_services).not_to be_empty }
    end
  end

  context 'SPSSODescriptors' do
    subject do
      @entity_source.known_entities
                    .map(&:entity_descriptor).flat_map(&:sp_sso_descriptors)
    end

    it 'has assertion consumer services' do
      subject.each do |sp|
        expect(sp.assertion_consumer_services).not_to be_empty
      end
    end
  end

  context 'AttributeAuthorityDescriptors' do
    subject do
      @entity_source.known_entities.map(&:entity_descriptor)
                    .flat_map(&:attribute_authority_descriptors)
    end

    it 'has attribute_services' do
      subject.each { |aa| expect(aa.attribute_services).not_to be_empty }
    end
  end

  context 'REFEDS entity category' do
    subject do
      @entity_source.known_entities.map(&:entity_descriptor)
                    .find_all { |ed| ed.sp_sso_descriptors.any? }
    end

    context 'Research and Scholarship' do
      it 'is created for each SPSSODescriptor' do
        expect(subject.size).to eq(2)
        subject.each do |ed|
          ed.entity_attribute.attributes.each do |a|
            expect(a.name).to eq('http://macedir.org/entity-category')
          end
        end
      end

      it 'advertises research and scholarship support' do
        subject.each do |ed|
          ed.entity_attribute.attributes.each do |a|
            expect(a.attribute_values[0].value)
              .to eq('http://refeds.org/category/research-and-scholarship')
          end
        end
      end
    end
  end

  context 'eduGAIN metadata profile v3' do
    context 'RegistrationInfo' do
      subject do
        @entity_source.known_entities
                      .map(&:entity_descriptor).map(&:registration_info)
      end

      it 'is created for each EntityDescriptor with authority and policies' do
        subject.each do |ri|
          expect(ri).to be_valid
          expect(ri.registration_authority).not_to be_nil
          expect(ri.registration_policies).not_to be_nil
        end
      end
    end

    context 'Organization' do
      subject do
        @entity_source.known_entities
                      .map(&:entity_descriptor).map(&:organization)
      end

      it 'is created for each EntityDescriptor with names and urls' do
        subject.each do |o|
          expect(o).to be_valid
          expect(o.organization_names).not_to be_nil
          expect(o.organization_display_names).not_to be_nil
          expect(o.organization_urls).not_to be_nil
        end
      end
    end

    context 'ContactPerson' do
      subject do
        @entity_source.known_entities
                      .map(&:entity_descriptor).flat_map(&:contact_people)
      end

      it 'has contact_person with email' do
        subject.each do |cp|
          expect(cp.contact_type).to eq(:technical)
          expect(cp.contact.email_address).not_to be nil
        end
      end
    end

    context 'SPSSODescriptor' do
      subject do
        @entity_source.known_entities
                      .map(&:entity_descriptor).flat_map(&:sp_sso_descriptors)
      end

      context 'mdui' do
        it 'has mdui:display_name and description' do
          subject.each do |sp|
            expect(sp.ui_info.display_names).not_to be_empty
            expect(sp.ui_info.descriptions).not_to be_empty
          end
        end
      end

      context 'requested_attributes' do
        it 'has attribute_consuming_service' do
          subject.each do |sp|
            expect(sp.attribute_consuming_services).not_to be_empty
            expect(sp.attribute_consuming_services[0].requested_attributes)
              .not_to be_empty
          end
        end
      end
    end
  end
end
