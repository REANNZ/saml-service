# frozen_string_literal: true

RSpec.shared_examples 'ETL::Contacts' do
  def create_json(id)
    {
      id:,
      given_name: Faker::Name.first_name,
      surname: Faker::Name.last_name,
      email: Faker::Internet.email,
      work_phone: Faker::PhoneNumber.phone_number,
      organization: { id: rand(10..200), name: Faker::Lorem.sentence },
      created_at: fr_time(contact_created_at)
    }
  end

  let(:contact_created_at) { Time.zone.at(rand(Time.now.utc.to_i)) }
  let(:contact_list) do
    total = contact_count + sirtfi_contact_count
    (0...total).reduce([]) { |a, e| a << create_json(1000 + e) }
  end

  before do
    stub_fr_request(:contacts)
  end

  def run
    described_class.new(id: fr_source.id).contacts
  end

  context 'creating a contact' do
    let(:contacts) { contact_list }
    let(:contact_count) { 1 }
    let(:sirtfi_contact_count) { 1 }
    before { run }
    subject { Contact.last }

    verify(created_at: -> { contact_created_at },
           updated_at: -> { truncated_now })
  end

  context 'updating a contact' do
    let(:fr_id) { rand(100..2000) }
    subject { create :contact }

    before do
      record_fr_id(subject, fr_id)
    end

    context 'updated contact' do
      let(:contacts) { [create_json(fr_id)] }

      verify(created_at: -> { subject.created_at },
             updated_at: -> { truncated_now })

      it 'updated created_at' do
        expect { run }
          .to change { subject.reload.created_at }
          .to eq(contact_created_at)
      end
    end
  end

  context 'contact json response' do
    let(:contacts) { contact_list }

    shared_examples 'obj creation' do
      it 'creates contact' do
        expect { run }.to change { Contact.count }
          .by(contact_count + sirtfi_contact_count)
      end
    end

    context 'single new contact' do
      let(:contact_count) { 1 }
      let(:sirtfi_contact_count) { 1 }
      include_examples 'obj creation'
    end

    context 'multiple new contacts' do
      let(:contact_count) { rand(2..20) }
      let(:sirtfi_contact_count) { rand(2..20) }
      include_examples 'obj creation'
    end

    context 'updating contacts' do
      let(:contact_count) { 1 }
      let(:sirtfi_contact_count) { 1 }
      before { run }

      context 'subsequent requests' do
        let(:contact_count) { 0 }
        let(:sirtfi_contact_count) { 0 }
        before { run }
        include_examples 'obj creation'
      end
    end
  end
end
