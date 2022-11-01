# frozen_string_literal: true

RSpec.shared_examples 'saml_uris' do
  it 'has expected data' do
    expect(source.count).to be > 0
    expect(target.count)
      .to eq(source.count)
    source.each_with_index do |s, i|
      expect(target[i].uri == s.uri)
    end
  end
end
