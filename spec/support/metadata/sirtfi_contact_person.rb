# frozen_string_literal: true

RSpec.shared_examples 'SIRTFI ContactPerson xml' do
  let(:contact_person_path) { '/ContactPerson' }
  let(:contact_person_company_path) { "#{contact_person_path}/Company" }
  let(:contact_person_given_name_path) { "#{contact_person_path}/GivenName" }
  let(:contact_person_surname_path) { "#{contact_person_path}/SurName" }
  let(:contact_person_email_address_path) do
    "#{contact_person_path}/EmailAddress"
  end
  let(:contact_person_telephone_number_path) do
    "#{contact_person_path}/TelephoneNumber"
  end
  let(:node) { xml.first(:xpath, contact_person_path) }

  it 'is created with contactType and remd:contactType' do
    expect(xml).to have_xpath(contact_person_path, count: 1)
    expect(node['contactType']).to eq('other')
    expect(node['remd:contactType'])
      .to eq('http://refeds.org/metadata/contactType/security')
  end

  context 'Company' do
    let(:node) { xml.first(:xpath, contact_person_company_path) }
    context 'when unknown' do
      let(:sirtfi_contact_person) do
        create :sirtfi_contact_person, :without_company
      end
      it 'is not created' do
        expect(xml).not_to have_xpath(contact_person_company_path)
      end
    end
    context 'when known' do
      it 'is created with company' do
        expect(xml).to have_xpath(contact_person_company_path, count: 1)
        expect(node.text).to eq(sirtfi_contact_person.contact.company)
      end
    end
  end

  context 'GivenName' do
    let(:node) { xml.first(:xpath, contact_person_given_name_path) }
    context 'when unknown' do
      let(:sirtfi_contact_person) do
        create :sirtfi_contact_person, :without_given_name
      end
      it 'is not created' do
        expect(xml).not_to have_xpath(contact_person_given_name_path)
      end
    end
    context 'when known' do
      it 'is created with contact person' do
        expect(xml).to have_xpath(contact_person_given_name_path, count: 1)
        expect(node.text).to eq(sirtfi_contact_person.contact.given_name)
      end
    end
  end

  context 'Surname' do
    let(:node) { xml.first(:xpath, contact_person_surname_path) }
    context 'when unknown' do
      let(:sirtfi_contact_person) do
        create :sirtfi_contact_person, :without_surname
      end
      it 'is not created' do
        expect(xml).not_to have_xpath(contact_person_surname_path)
      end
    end
    context 'when known' do
      it 'is created with surname' do
        expect(xml).to have_xpath(contact_person_surname_path, count: 1)
        expect(node.text).to eq(sirtfi_contact_person.contact.surname)
      end
    end
  end

  context 'EmailAddress' do
    let(:node) { xml.first(:xpath, contact_person_email_address_path) }
    context 'when unknown' do
      let(:sirtfi_contact_person) do
        create :sirtfi_contact_person, :without_email_address
      end
      it 'is not created' do
        expect(xml).not_to have_xpath(contact_person_email_address_path)
      end
    end
    context 'when known' do
      it 'is created with email' do
        expect(xml).to have_xpath(contact_person_email_address_path, count: 1)
        expect(node.text)
          .to eq("mailto:#{sirtfi_contact_person.contact.email_address}")
      end
    end
  end

  context 'TelephoneNumber' do
    let(:node) { xml.first(:xpath, contact_person_telephone_number_path) }
    context 'when unknown' do
      let(:sirtfi_contact_person) do
        create :sirtfi_contact_person, :without_telephone_number
      end
      it 'is not created' do
        expect(xml).not_to have_xpath(contact_person_telephone_number_path)
      end
    end
    context 'when known' do
      it 'is created with telephone' do
        expect(xml)
          .to have_xpath(contact_person_telephone_number_path, count: 1)
        expect(node.text).to eq(sirtfi_contact_person.contact.telephone_number)
      end
    end
  end
end
