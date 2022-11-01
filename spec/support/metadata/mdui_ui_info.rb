# frozen_string_literal: true

RSpec.shared_examples 'mdui:UIInfo xml' do
  let(:mdui_ui_info_path) { '/mdui:UIInfo' }
  let(:mdui_display_name_path) { "#{mdui_ui_info_path}/mdui:DisplayName" }
  let(:mdui_description_path) { "#{mdui_ui_info_path}/mdui:Description" }
  let(:mdui_keywords_path) { "#{mdui_ui_info_path}/mdui:Keywords" }
  let(:mdui_logo_path) { "#{mdui_ui_info_path}/mdui:Logo" }
  let(:mdui_informationurl_path) { "#{mdui_ui_info_path}/mdui:InformationURL" }
  let(:mdui_privacystatementurl_path) do
    "#{mdui_ui_info_path}/mdui:PrivacyStatementURL"
  end

  it 'is created with ui info and display_name and description path' do
    expect(xml).to have_xpath(mdui_ui_info_path, count: 1)
    expect(xml).to have_xpath(mdui_display_name_path, count: 1)
    expect(xml).to have_xpath(mdui_description_path, count: 1)
  end

  context 'DisplayName' do
    context 'rendered node' do
      let(:node) { xml.first(:xpath, mdui_display_name_path) }
      it 'sets language and text' do
        expect(node['xml:lang']).to eq(ui_info.display_names.first.lang)
        expect(node.text).to eq(ui_info.display_names.first.value)
      end
    end

    context 'multiple display names' do
      let(:ui_info) { create :mdui_ui_info, :with_multiple_display_names }
      it 'creates multiple nodes' do
        expect(xml).to have_xpath(mdui_display_name_path, count: 2)
      end
    end
  end

  context 'Description' do
    context 'rendered node' do
      let(:node) { xml.first(:xpath, mdui_description_path) }
      it 'sets language and text' do
        expect(node['xml:lang']).to eq(ui_info.descriptions.first.lang)
        expect(node.text).to eq(ui_info.descriptions.first.value)
      end
    end

    context 'multiple display names' do
      let(:ui_info) { create :mdui_ui_info, :with_multiple_descriptions }
      it 'creates multiple nodes' do
        expect(xml).to have_xpath(mdui_description_path, count: 2)
      end
    end
  end

  context 'Keywords' do
    let(:ui_info) { create :mdui_ui_info, :with_content }

    it 'is created' do
      expect(xml).to have_xpath(mdui_keywords_path, count: 1)
    end

    context 'rendered node' do
      let(:node) { xml.first(:xpath, mdui_keywords_path) }
      it 'sets language and text' do
        expect(node['xml:lang']).to eq(ui_info.keyword_lists.first.lang)
        expect(node.text).to eq(ui_info.keyword_lists.first.content)
      end
    end
  end

  context 'Logo' do
    let(:ui_info) { create :mdui_ui_info, :with_content }

    it 'is created' do
      expect(xml).to have_xpath(mdui_logo_path, count: 1)
    end

    context 'rendered node' do
      let(:node) { xml.first(:xpath, mdui_logo_path) }
      it 'sets language, height, width and text' do
        expect(node['xml:lang']).to eq(ui_info.logos.first.lang)
        expect(node['height']).to eq(ui_info.logos.first.height.to_s)
        expect(node['width']).to eq(ui_info.logos.first.width.to_s)
        expect(node.text).to eq(ui_info.logos.first.uri)
      end
    end
  end

  context 'InformationURL' do
    let(:ui_info) { create :mdui_ui_info, :with_content }

    it 'is created' do
      expect(xml).to have_xpath(mdui_informationurl_path, count: 1)
    end

    context 'rendered node' do
      let(:node) { xml.first(:xpath, mdui_informationurl_path) }
      it 'sets language and text' do
        expect(node['xml:lang']).to eq(ui_info.information_urls.first.lang)
        expect(node.text).to eq(ui_info.information_urls.first.uri)
      end
    end
  end

  context 'PrivacyStatementURL' do
    let(:ui_info) { create :mdui_ui_info, :with_content }

    it 'is created' do
      expect(xml).to have_xpath(mdui_privacystatementurl_path, count: 1)
    end

    context 'rendered node' do
      let(:node) { xml.first(:xpath, mdui_privacystatementurl_path) }
      it 'sets language and text' do
        expect(node['xml:lang'])
          .to eq(ui_info.privacy_statement_urls.first.lang)
        expect(node.text).to eq(ui_info.privacy_statement_urls.first.uri)
      end
    end
  end
end
