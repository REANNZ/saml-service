# frozen_string_literal: true

module Etl
  module Contacts
    def contacts
      fr_contacts.each do |contact_data|
        contact(contact_data)
      end
    end

    def contact(contact_data)
      ds = Contact.dataset
      create_or_update_by_fr_id(ds, contact_data[:id],
                                contact_attrs(contact_data))
    end

    def contact_attrs(contact_data)
      { created_at: Time.zone.parse(contact_data[:created_at]),
        given_name: contact_data[:given_name],
        surname: contact_data[:surname],
        email_address: contact_data[:email],
        telephone_number: contact_data[:work_phone],
        company: contact_data[:organization][:name] }
    end
  end
end
