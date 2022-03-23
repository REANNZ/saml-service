# frozen_string_literal: true

class KnownEntity < Sequel::Model
  plugin :touch

  many_to_one :entity_source
  one_to_one :entity_descriptor
  one_to_one :raw_entity_descriptor

  one_to_many :tags

  plugin :association_dependencies, entity_descriptor: :destroy,
                                    raw_entity_descriptor: :destroy,
                                    tags: :destroy

  alias enabled? enabled

  def validate
    super
    validates_presence %i[entity_source enabled created_at updated_at]
  end

  def self.permitted_entities
    dataset.qualify
           .left_outer_join(Sequel.as(:tags, :blacklist_tags),
                            known_entity_id: :id,
                            name: Tag::BLACKLIST)
           .where(Sequel.qualify(:blacklist_tags, :id) => nil)
  end

  def self.with_any_tag(tags, include_blacklisted: false)
    join_tags(tags, include_blacklisted: include_blacklisted).all
  end

  def self.with_all_tags(tags, include_blacklisted: false)
    join_tags(tags, include_blacklisted: include_blacklisted)
      .having { Sequel.lit("count(*) = #{[tags].flatten.length}") }.all
  end

  def self.join_tags(tags, include_blacklisted: false)
    dataset = if include_blacklisted
                self.dataset.qualify
              else
                qualify.from(Sequel.as(permitted_entities, :known_entities))
              end

    dataset.join(:tags, known_entity_id: :id, name: tags)
           .group(Sequel.qualify(:tags, :known_entity_id))
  end

  def tag_as(name)
    return if tags.any? { |t| t.name == name }

    add_tag(Tag.new(name: name))
    update_derived_tags
  end

  def untag_as(name)
    tags.delete_if { |t| t.name == name }
    Tag.where(name: name, known_entity: self).destroy
    update_derived_tags
  end

  def entity_id
    return entity_descriptor.entity_id.uri if entity_descriptor
    return raw_entity_descriptor.entity_id.uri if raw_entity_descriptor

    nil
  end

  def update_derived_tags
    current_derived_tags, current_tags =
      tags.partition(&:derived?).map { |t| t.map(&:name) }

    desired_derived_tags = DerivedTag.all.flat_map do |dt|
      [dt.tag_name].select { dt.matches?(current_tags) }
    end

    (current_derived_tags - desired_derived_tags)
      .each { |tag| remove_derived_tag(tag) }

    desired_derived_tags.each { |tag| apply_derived_tag(tag) }
  end

  def functioning_entity
    return entity_descriptor if entity_descriptor.try(:functioning?)
    return raw_entity_descriptor if raw_entity_descriptor.try(:functioning?)

    nil
  end

  private

  def apply_derived_tag(name)
    return if tags.any? { |t| t.name == name }

    add_tag(name: name, derived: true)
  end

  def remove_derived_tag(name)
    tags.delete_if { |t| t.name == name && t.derived? }
    Tag.where(known_entity_id: id, name: name, derived: true).destroy
  end
end
