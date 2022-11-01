# frozen_string_literal: true

RSpec.shared_examples 'key_descriptors' do
  it 'has source data' do
    expect(source.count).to be > 0
    expect(target.count)
      .to eq(source.count)
    source.each_with_index do |s, i|
      expect(target[i].key_type).to eq(s.key_type)
    end
  end

  context 'key info' do
    it 'sets expected data' do
      source.each_with_index do |s, i|
        expect({
                 key_name: target[i].key_info.key_name,
                 subject: target[i].key_info.subject,
                 issuer: target[i].key_info.issuer,
                 data: target[i].key_info.data
               }).to match({
                             key_name: s.key_info.key_name,
                             subject: s.key_info.subject,
                             issuer: s.key_info.issuer,
                             data: s.key_info.data.strip
                           })
      end
    end
  end
end
