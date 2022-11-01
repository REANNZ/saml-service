# frozen_string_literal: true

RSpec.shared_examples 'mdui:DiscoHints xml' do
  let(:mdui_disco_path) { '/mdui:DiscoHints' }
  let(:ip_hint_path) { "#{mdui_disco_path}/mdui:IPHint" }
  let(:domain_hint_path) { "#{mdui_disco_path}/mdui:DomainHint" }
  let(:geolocation_hint_path) { "#{mdui_disco_path}/mdui:GeolocationHint" }

  it 'is created with IPHints and domain hints and geolocation hints and disco hints' do
    expect(xml).to have_xpath(mdui_disco_path, count: 1)
    expect(xml).to have_xpath(ip_hint_path, count: 1)
    expect(xml).to have_xpath(domain_hint_path, count: 1)
    expect(xml).to have_xpath(geolocation_hint_path, count: 1)
  end

  context 'IPHints rendered node' do
    let(:node) { xml.first(:xpath, ip_hint_path) }
    it 'sets correct value' do
      expect(node.text).to eq(disco_hints.ip_hints.first.block)
    end
  end

  context 'DomainHint rendered node' do
    let(:node) { xml.first(:xpath, domain_hint_path) }
    it 'sets correct value' do
      expect(node.text).to eq(disco_hints.domain_hints.first.domain)
    end
  end

  context 'GeolocationHint rendered node' do
    let(:node) { xml.first(:xpath, geolocation_hint_path) }
    it 'sets correct value' do
      expect(node.text).to eq(disco_hints.geolocation_hints.first.uri)
    end
  end
end
