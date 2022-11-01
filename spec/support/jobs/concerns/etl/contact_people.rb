# frozen_string_literal: true

RSpec.shared_examples 'contact_people' do
  it 'has expected data' do
    expect(source.count).to be > 0
    expect(target.count)
      .to eq(source.count)
    source.each_with_index do |s, i|
      expect(target[i].contact_type.to_s).to eq(s[:type][:name])
      expect(
        {
          email: target[i].contact.email_address,
          given_name: target[i].contact.given_name,
          surname: target[i].contact.surname
        }
      ).to match(
        {
          email: contact_instances[i].email_address,
          given_name: contact_instances[i].given_name,
          surname: contact_instances[i].surname
        }
      )
    end
  end
end
