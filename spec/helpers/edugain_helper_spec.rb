# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EdugainHelper, type: :helper do
  context 'with no config provided' do
    before do
      allow(Rails.application.config.saml_service.api).to receive(:edugain_export_tag_name).and_return(nil)
      allow(Rails.application.config.saml_service.api).to receive(:edugain_verified_tag_name).and_return(nil)
    end

    describe '#edugain_export_tag' do
      it 'returns default tag value' do
        expect(EdugainHelper.edugain_export_tag).to eql(EdugainHelper::DEFAULT_EDUGAIN_EXPORT_TAG_NAME)
      end
    end

    describe '#edugain_verified_tag' do
      it 'returns default tag value' do
        expect(EdugainHelper.edugain_verified_tag).to eql(EdugainHelper::DEFAULT_EDUGAIN_VERIFIED_TAG_NAME)
      end
    end
  end

  context 'with config overriding tag names' do
    let(:export_tag) { Faker::Lorem.word }
    let(:verified_tag) { Faker::Lorem.word }

    before do
      allow(Rails.application.config.saml_service.api).to receive(:edugain_export_tag_name).and_return(export_tag)
      allow(Rails.application.config.saml_service.api).to receive(:edugain_verified_tag_name).and_return(verified_tag)
    end

    describe '#edugain_export_tag' do
      it 'returns overriding tag value' do
        expect(EdugainHelper.edugain_export_tag).to eql(export_tag)
      end
    end

    describe '#edugain_verified_tag' do
      it 'returns overriding tag value' do
        expect(EdugainHelper.edugain_verified_tag).to eql(verified_tag)
      end
    end
  end
end
