# frozen_string_literal: true

require 'rails_helper'

RSpec.describe API::Edugain::NonResearchAndScholarshipEntityApprovalsController, type: :request do
  let(:entity_descriptor) { create(:entity_descriptor, :with_sp) }
  let(:entity_id) { entity_descriptor.entity_id.uri }

  let(:api_subject) { create(:api_subject, :token, :authorized) }

  describe 'POST /api/edugain/non_research_and_scholarship_entity_approvals' do
    subject(:run) do
      post '/api/edugain/non_research_and_scholarship_entity_approvals',
           params: { entity_id: entity_id },
           headers: { Authorization: +"Bearer #{api_subject.token}" }
    end

    it 'tags the KnownEntity as aaf-edugain-verified' do
      expect(entity_descriptor.known_entity.tags).to be_empty

      run
      entity_descriptor.reload

      expect(entity_descriptor.known_entity.tags.first.name).to eq 'aaf-edugain-verified'
      expect(response).to have_http_status :no_content
    end
  end
end
