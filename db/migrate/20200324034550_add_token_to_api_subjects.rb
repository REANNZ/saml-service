Sequel.migration do
  change do
    alter_table(:api_subjects) do
      add_column :token, String, null: true
      add_index :token, unique: true
      set_column_allow_null :x509_cn
    end
  end
end
