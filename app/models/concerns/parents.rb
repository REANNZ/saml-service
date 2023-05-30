# frozen_string_literal: true

module Parents
  extend ActiveSupport::Concern

  def single_parent(parents)
    parent_instances = parents.map { |parent| send(parent) }.compact
    return if parent_instances.one?

    if parent_instances.none?
      errors.add(:ownership, "Must be owned by one of #{parents.join(', ')}")
    else
      errors.add(:ownership, 'Cannot be owned by more than one of ' \
                             "#{parents.join(', ')}")
    end
  end
end
