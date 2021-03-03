# frozen_string_literal: true

namespace :edugain do
  task :publish_idp, [:eid] => :environment do |_t, args|
    eid = entity_id(args[:eid])
    ed = eid.entity_descriptor
    ea = find_create_entity_attribute(ed)

    add_rs_to_idp(ea)
    add_sirtfi(ea)
    tag_ed(ed, 'aaf-edugain-export')

    finalize(ed)
  end

  task :publish_sp, %i[eid info_url] => :environment do |_t, args|
    eid = entity_id(args[:eid])
    ed = eid.entity_descriptor
    ea = find_create_entity_attribute(ed)

    if args[:info_url].blank?
      p 'An information_url must be provided as a second argument to this task'
      exit
    end

    add_rs_to_sp(ea)
    add_sirtfi(ea)
    add_info_url_to_sp(ed, args[:info_url])
    tag_ed(ed, 'aaf-edugain-export')

    finalize(ed)
  end

  task :approve_non_rs_entity, [:eid] => :environment do |_t, args|
    eid = entity_id(args[:eid])
    ed = eid.raw_entity_descriptor

    tag_ed(ed, 'aaf-edugain-verified')

    finalize(ed)
  end
end

def entity_id(eid)
  if eid.blank?
    p 'An entity_id must be provided as an argument to this task'
    exit
  end

  entity_id = EntityId[uri: eid]
  if entity_id.nil?
    p "Could not find an entry for supplied entity_id '#{eid}'"
    exit
  end
  entity_id
end

def find_create_entity_attribute(ed)
  ed.entity_attribute || MDATTR::EntityAttribute.create(entity_descriptor: ed)
end

def tag_ed(ed, tag)
  ed.known_entity.tag_as(tag)
end

def add_rs_to_idp(ea)
  a = Attribute.create(name: 'http://macedir.org/entity-category-support', entity_attribute: ea)
  NameFormat.create(attribute: a, uri: 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri')
  AttributeValue.create(value: 'http://refeds.org/category/research-and-scholarship', attribute: a)
end

def add_rs_to_sp(ea)
  a = Attribute.create(name: 'http://macedir.org/entity-category', entity_attribute: ea)
  NameFormat.create(attribute: a, uri: 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri')
  AttributeValue.create(value: 'http://refeds.org/category/research-and-scholarship', attribute: a)
end

def add_info_url_to_sp(ed, information_url)
  ed.sp_sso_descriptors.each do |rd|
    ui_info = rd.ui_info || raise('no UIInfo, should not be possible')
    next if ui_info.information_urls.any?

    MDUI::InformationURL.create(ui_info: ui_info, uri: information_url, lang: 'en')
  end
end

def add_sirtfi(ea)
  a = Attribute.create(name: 'urn:oasis:names:tc:SAML:attribute:assurance-certification',
                       entity_attribute: ea)
  NameFormat.create(attribute: a, uri: 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri')
  AttributeValue.create(value: 'https://refeds.org/sirtfi', attribute: a)
end

def finalize(ed)
  ed.save(raise_on_save_failure: true)
  ed.known_entity.touch

  puts 'Updated eduGAIN status successfully'
end
