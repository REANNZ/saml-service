# frozen_string_literal: true

module StoreFederationRegistryData
  def create_or_update_by_fr_id(dataset, fr_id, attrs)
    update_by_fr_id(dataset, fr_id, attrs) { |o| yield o if block_given? } ||
      create_by_fr_id(dataset, fr_id, attrs) { |o| yield o if block_given? }
  end

  private

  def create_by_fr_id(dataset, fr_id, attrs)
    obj = dataset.model.new(attrs)
    # :nocov:
    yield obj if block_given?
    # :nocov:
    obj.save
    record_fr_id(obj, fr_id)
    obj
  end

  def update_by_fr_id(dataset, fr_id, attrs)
    obj = FederationRegistryObject.local_instance(fr_id, dataset)
    # Avoid saving early, as validationa would fail
    obj.try(:set, attrs)
    yield obj if obj && block_given?
    # explicitly save changes (and use safe navigation in case obj is nil)
    # but not in test env, as some test cases do not validate (and cannot be saved)
    # however, even in test, still save if obj&.modified holds to compensate for set insted of update above
    # TODO: fix test setup to be able to always save when running tests
    # :nocov:
    obj&.save unless Rails.env.test? && !obj&.modified?
    # :nocov:
    obj
  end

  def record_fr_id(object, fr_id)
    ds = FederationRegistryObject[internal_class_name: object.class.name,
                                  fr_id:]
    ds.try!(&:delete)

    FederationRegistryObject.create(internal_class_name: object.class.name,
                                    internal_id: object.id,
                                    fr_id:)
  end
end
