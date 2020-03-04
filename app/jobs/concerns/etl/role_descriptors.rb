# frozen_string_literal: true

module ETL
  module RoleDescriptors
    def role_descriptor(rd, rd_data, scopes_data)
      scopes(rd, scopes_data) if scopes_data
      contact_people(rd, rd_data[:contact_people])
      protocol_supports(rd, rd_data[:protocol_support_enumerations])
      key_descriptors(rd, rd_data[:key_descriptors])
    end

    def scopes(rd, scope_data)
      # Any scopes which we've added locally i.e. no knowledge
      # from FR are not removed
      rd.scopes.select(&:unlocked?).each(&:destroy)
      rd.add_scope(SHIBMD::Scope.new(value: scope_data,
                                     regexp: regexp_scope?(scope_data)))
    end

    def contact_people(rd, contact_people)
      # Contacts are stored at the ED level only within saml-service
      # This is more inline with eduGain policy and prevents duplication
      destroy_all_contact_people(rd)
      contact_people.each do |contact_person|
        type = contact_person[:type][:name].downcase.to_sym
        next unless ContactPerson::TYPE.key?(type) || type == :security

        c = rd_contact(contact_person)
        next unless c

        next contact_person(rd, c, type) unless type == :security

        sirtfi_contact_person(rd, c)
      end
    end

    def destroy_all_contact_people(role_descriptor)
      role_descriptor.entity_descriptor.contact_people.each(&:destroy)
      role_descriptor.entity_descriptor.sirtfi_contact_people.each(&:destroy)
    end

    def contact_person(role_descriptor, contact, type)
      entity_descriptor = role_descriptor.entity_descriptor
      cp = ContactPerson.create(contact: contact, contact_type: type)
      entity_descriptor.add_contact_person(cp)
    end

    def sirtfi_contact_person(role_descriptor, contact)
      entity_descriptor = role_descriptor.entity_descriptor
      cp = SIRTFIContactPerson.create(contact: contact)
      entity_descriptor.add_sirtfi_contact_person(cp)
    end

    def rd_contact(contact_person)
      FederationRegistryObject.local_instance(contact_person[:contact][:id],
                                              Contact.dataset)
    end

    def regexp_scope?(scope)
      !(scope =~ /\^(.+)\$/).nil?
    end

    def protocol_supports(rd, protocol_support_data)
      rd.protocol_supports.each(&:destroy)
      protocol_support_data.each do |ps|
        rd.add_protocol_support(ProtocolSupport.new(uri: ps[:uri]))
      end
    end

    def key_descriptors(rd, key_descriptor_data)
      rd.key_descriptors.each(&:destroy)

      key_descriptor_data.each do |kd_data|
        rd.add_key_descriptor(key_descriptor(kd_data))
      rescue OpenSSL::X509::CertificateError => e
        log_key_descriptor_error(kd_data, e)
      end
    end

    def log_key_descriptor_error(kd_data, e)
      Rails.logger.info(
        "FR Certificate \n#{kd_data[:key_info][:certificate][:data]}\n" \
        "was invalid and not persisted due to: #{e.message}"
      )
    end

    def key_descriptor(kd_data)
      key_type = kd_data.key?(:type) ? kd_data[:type].to_sym : nil
      kd = KeyDescriptor.create(key_type: key_type,
                                disabled: kd_data.fetch(:disabled, false))
      key_info(kd, kd_data)
      kd
    end

    def key_info(kd, kd_data)
      return unless kd_data.key?(:key_info)

      ki_data = kd_data[:key_info]
      return unless ki_data.key?(:certificate)

      cert = ki_data[:certificate]
      return unless cert.key?(:data)

      ki = KeyInfo.create(key_name: ki_data.fetch(:name, nil),
                          subject: cert.fetch(:subject, nil),
                          issuer: cert.fetch(:issuer, nil),
                          data: clean_certificate_data(cert[:data]))

      kd.update(key_info: ki)
    end

    def mdui(rd, display_name, description)
      ui_info = rd.ui_info || MDUI::UIInfo.create(role_descriptor: rd)
      ui_info.display_names.each(&:destroy)
      ui_info.descriptions.each(&:destroy)

      ui_info.add_display_name(MDUI::DisplayName.new(value: display_name,
                                                     lang: 'en'))
      ui_info.add_description(MDUI::Description.new(value: description.squish,
                                                    lang: 'en'))
    end

    def clean_certificate_data(data)
      data.gsub(/\\n/, "\n").lines.map(&:strip)
          .flat_map { |l| l.chars.each_slice(72).map(&:join).to_a }.join("\n")
    end
  end
end
