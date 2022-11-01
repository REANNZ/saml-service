# frozen_string_literal: true

RSpec.shared_examples 'endpoint' do
  it 'sets expected data' do
    expect(source.count).to be > 0
    expect(target.count)
      .to eq(source.count)
    source.each_with_index do |s, i|
      expect(
        { location: target[i].location, binding: target[i].binding }
      ).to match({
                   location: s.location, binding: s.binding
                 })
    end
  end
end

RSpec.shared_examples 'indexed_endpoint' do
  include_examples 'endpoint'

  it 'sets expected data' do
    source.each_with_index do |s, i|
      expect(
        { is_default: target[i].is_default, index: target[i].index }
      ).to match({
                   is_default: s.is_default, index: s.index
                 })
    end
  end
end
