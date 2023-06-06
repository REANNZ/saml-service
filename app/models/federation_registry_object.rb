# frozen_string_literal: true

class FederationRegistryObject < Sequel::Model
  def self.local_instance(fr_id, dataset)
    fr_obj = find(fr_id:, internal_class_name: dataset.model.name)

    return dataset[fr_obj.internal_id] if fr_obj

    nil
  end
end
