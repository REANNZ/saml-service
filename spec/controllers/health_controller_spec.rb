# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HealthController, type: :controller do
  describe 'GET #show' do
    subject(:show) { get :show }

    context 'when services are accessible' do
      it 'returns http success' do
        show
        expect(response).to have_http_status(:success)
        expect(response.parsed_body.symbolize_keys).to match(
          hash_including({
                           version: 'VERSION_PROVIDED_ON_BUILD',
                           redis_active: true,
                           db_active: true
                         })
        )
      end
    end

    context 'when redis is inaccessible' do
      before do
        allow(HealthController).to receive(:redis).and_throw(StandardError)
      end
      it 'returns http 503' do
        show
        expect(response.parsed_body.symbolize_keys).to match(
          hash_including({
                           redis_active: false
                         })
        )
        expect(response).to have_http_status(:service_unavailable)
      end
    end

    context 'when db is inaccessible' do
      before do
        allow(Sequel::Model.db).to receive(:test_connection).and_throw(StandardError)
      end

      it 'returns http 503' do
        show
        expect(response).to have_http_status(:service_unavailable)
        expect(response.parsed_body.symbolize_keys).to match(
          hash_including({
                           db_active: false
                         })
        )
      end
    end
  end
end
