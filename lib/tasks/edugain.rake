# frozen_string_literal: true

namespace :edugain do
  task :publish_idp, [:eid] => :environment do |_t, args|
    Edugain::IdentityProviderExport.new(entity_id: args[:eid]).save
    puts 'Updated eduGAIN status successfully'
  end

  task :publish_sp, %i[eid info_url] => :environment do |_t, args|
    Edugain::ServiceProviderExport.new(
      entity_id: args[:eid],
      information_url: args[:info_url]
    ).save
    puts 'Updated eduGAIN status successfully'
  end

  task :approve_non_rs_entity, [:eid] => :environment do |_t, _args|
    Edugain::NonResearchAndScholarshipEntity.new(id: eid).approve
    puts 'Updated eduGAIN status successfully'
  end
end
