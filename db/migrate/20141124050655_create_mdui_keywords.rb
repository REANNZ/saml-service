Sequel.migration do
  change do

    create_table :keyword_lists do
      primary_key :id
      foreign_key :ui_info_id, :ui_infos, null: true,
                  foreign_key_constraint_name: 'keyl_ui_info_fkey'

      String :lang
      Text :content

      DateTime :created_at
      DateTime :updated_at

    end

  end
end
