Sequel.migration do
  change do
    create_table(:api_subjects) do
      primary_key :id, :type=>"int(11)"
      column :x509_cn, "varchar(255)"
      column :description, "varchar(255)", :null=>false
      column :contact_name, "varchar(255)", :null=>false
      column :contact_mail, "varchar(255)", :null=>false
      column :enabled, "tinyint(1)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      column :token, "varchar(255)"
      
      index [:token], :unique=>true
      index [:x509_cn], :name=>:x509_cn, :unique=>true
    end
    
    create_table(:authz_services) do
      primary_key :id, :type=>"int(11)"
    end
    
    create_table(:contacts) do
      primary_key :id, :type=>"int(11)"
      column :given_name, "varchar(255)"
      column :surname, "varchar(255)"
      column :email_address, "varchar(255)"
      column :telephone_number, "varchar(255)"
      column :company, "varchar(255)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
    end
    
    create_table(:derived_tags) do
      primary_key :id, :type=>"int(11)"
      column :tag_name, "varchar(255)", :null=>false
      column :when_tags, "varchar(255)", :null=>false
      column :unless_tags, "varchar(255)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
    end
    
    create_table(:endpoints) do
      primary_key :id, :type=>"int(11)"
      column :binding, "varchar(255)", :null=>false
      column :location, "varchar(255)", :null=>false
      column :response_location, "varchar(255)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
    end
    
    create_table(:entity_sources) do
      primary_key :id, :type=>"int(11)"
      column :rank, "bigint(20)", :null=>false
      column :enabled, "tinyint(1)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :url, "varchar(255)"
      column :certificate, "varchar(4096)"
      column :source_tag, "varchar(255)", :null=>false
      
      index [:source_tag], :name=>:source_tag, :unique=>true
    end
    
    create_table(:federation_registry_objects) do
      primary_key :id, :type=>"int(11)"
      column :internal_class_name, "varchar(255)", :null=>false
      column :internal_id, "int(11)", :null=>false
      column :fr_id, "int(11)", :null=>false
    end
    
    create_table(:indexed_endpoints) do
      primary_key :id, :type=>"int(11)"
      column :is_default, "tinyint(1)", :null=>false
      column :index, "int(11)", :null=>false
    end
    
    create_table(:keypairs) do
      primary_key :id, :type=>"int(11)"
      column :certificate, "varchar(4096)", :null=>false
      column :key, "varchar(4096)", :null=>false
      column :fingerprint, "varchar(40)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:fingerprint], :unique=>true
    end
    
    create_table(:known_entities) do
      primary_key :id, :type=>"int(11)"
      column :enabled, "tinyint(1)", :null=>false
      column :entity_source_id, "int(11)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
    end
    
    create_table(:localized_names) do
      primary_key :id, :type=>"int(11)"
      column :value, "varchar(2048)", :null=>false
      column :lang, "varchar(255)", :null=>false
      column :created_at, "datetime"
      column :updated_at, "datetime"
    end
    
    create_table(:localized_uris) do
      primary_key :id, :type=>"int(11)"
      column :uri, "text", :null=>false
      column :lang, "varchar(255)", :null=>false
      column :created_at, "datetime"
      column :updated_at, "datetime"
    end
    
    create_table(:organizations) do
      primary_key :id, :type=>"int(11)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
    end
    
    create_table(:roles) do
      primary_key :id, :type=>"int(11)"
      column :name, "varchar(255)", :null=>false
      column :created_at, "datetime"
      column :updated_at, "datetime"
    end
    
    create_table(:schema_migrations) do
      column :filename, "varchar(255)", :null=>false
      
      primary_key [:filename]
    end
    
    create_table(:sso_descriptors) do
      primary_key :id, :type=>"int(11)"
    end
    
    create_table(:subjects) do
      primary_key :id, :type=>"int(11)"
      column :targeted_id, "varchar(255)"
      column :shared_token, "varchar(255)"
      column :name, "varchar(255)"
      column :mail, "varchar(255)"
      column :enabled, "tinyint(1)"
      column :complete, "tinyint(1)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
    end
    
    create_table(:api_subjects_roles) do
      foreign_key :role_id, :roles, :type=>"int(11)", :null=>false, :key=>[:id]
      foreign_key :api_subject_id, :api_subjects, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:role_id], :name=>:api_subject_role_fkey
      index [:api_subject_id], :name=>:role_api_subject_fkey
    end
    
    create_table(:artifact_resolution_services) do
      primary_key :id, :type=>"int(11)"
      foreign_key :sso_descriptor_id, :sso_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:sso_descriptor_id], :name=>:sso_ars_fkey
    end
    
    create_table(:entity_descriptors) do
      primary_key :id, :type=>"int(11)"
      foreign_key :organization_id, :organizations, :type=>"int(11)", :key=>[:id]
      column :extensions, "text"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :known_entity_id, :known_entities, :type=>"int(11)", :null=>false, :key=>[:id]
      column :enabled, "tinyint(1)", :default=>false
      
      index [:known_entity_id], :name=>:known_entity_id_key
      index [:organization_id], :name=>:organization_id_key
    end
    
    create_table(:federation_registry_sources) do
      primary_key :id, :type=>"int(11)"
      foreign_key :entity_source_id, :entity_sources, :type=>"int(11)", :null=>false, :key=>[:id]
      column :hostname, "varchar(255)", :null=>false
      column :secret, "varchar(255)", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :registration_authority, "varchar(255)", :null=>false
      column :registration_policy_uri, "varchar(255)", :null=>false
      column :registration_policy_uri_lang, "varchar(255)", :null=>false
      
      index [:entity_source_id], :name=>:entity_source_id
    end
    
    create_table(:manage_name_id_services) do
      primary_key :id, :type=>"int(11)"
      foreign_key :sso_descriptor_id, :sso_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:sso_descriptor_id], :name=>:sso_mnid_fkey
    end
    
    create_table(:metadata_instances) do
      primary_key :id, :type=>"int(11)"
      column :name, "varchar(255)", :null=>false
      column :extensions, "text"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      column :ca_verify_depth, "int(11)"
      column :hash_algorithm, "varchar(255)", :null=>false
      foreign_key :keypair_id, :keypairs, :type=>"int(11)", :null=>false, :key=>[:id]
      column :identifier, "varchar(255)", :null=>false
      column :all_entities, "tinyint(1)", :default=>true, :null=>false
      column :federation_identifier, "varchar(255)", :null=>false
      column :validity_period, "int(11)", :null=>false
      column :cache_period, "int(11)", :default=>21600, :null=>false
      column :primary_tag, "varchar(255)", :null=>false
      
      index [:keypair_id], :name=>:keypair_id
      index [:identifier], :unique=>true
    end
    
    create_table(:organization_display_names) do
      primary_key :id, :type=>"int(11)"
      foreign_key :organization_id, :organizations, :type=>"int(11)", :null=>false, :key=>[:id]
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:organization_id], :name=>:org_odn_ln_fkey
    end
    
    create_table(:organization_names) do
      primary_key :id, :type=>"int(11)"
      foreign_key :organization_id, :organizations, :type=>"int(11)", :null=>false, :key=>[:id]
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:organization_id], :name=>:org_on_ln_fkey
    end
    
    create_table(:organization_urls) do
      primary_key :id, :type=>"int(11)"
      foreign_key :organization_id, :organizations, :type=>"int(11)", :null=>false, :key=>[:id]
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:organization_id], :name=>:org_ou_lu_fkey
    end
    
    create_table(:permissions) do
      primary_key :id, :type=>"int(11)"
      foreign_key :role_id, :roles, :type=>"int(11)", :null=>false, :key=>[:id]
      column :value, "varchar(255)", :null=>false
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:role_id], :name=>:perm_role_fkey
    end
    
    create_table(:raw_entity_descriptors) do
      primary_key :id, :type=>"int(11)"
      foreign_key :known_entity_id, :known_entities, :type=>"int(11)", :null=>false, :key=>[:id]
      column :xml, "mediumtext", :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :enabled, "tinyint(1)", :default=>false
      column :idp, "tinyint(1)", :default=>false
      column :sp, "tinyint(1)", :default=>false
      column :standalone_aa, "tinyint(1)", :default=>false
      
      index [:known_entity_id], :unique=>true
    end
    
    create_table(:roles_subjects) do
      foreign_key :role_id, :roles, :type=>"int(11)", :null=>false, :key=>[:id]
      foreign_key :subject_id, :subjects, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:subject_id], :name=>:role_subject_fkey
      index [:role_id], :name=>:subject_role_fkey
    end
    
    create_table(:single_logout_services) do
      primary_key :id, :type=>"int(11)"
      foreign_key :sso_descriptor_id, :sso_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:sso_descriptor_id], :name=>:sso_slo_fkey
    end
    
    create_table(:tags) do
      primary_key :id, :type=>"int(11)"
      column :name, "varchar(255)", :null=>false
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :known_entity_id, :known_entities, :type=>"int(11)", :key=>[:id]
      column :derived, "tinyint(1)", :default=>false
      
      index [:known_entity_id], :name=>:known_entity_id
      index [:name, :known_entity_id], :name=>:name_known_entity_id_un, :unique=>true
    end
    
    create_table(:additional_metadata_locations) do
      primary_key :id, :type=>"int(11)"
      column :uri, "varchar(255)", :null=>false
      column :namespace, "varchar(255)", :null=>false
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :entity_descriptor_id, :entity_descriptors, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:entity_descriptor_id], :name=>:entity_descriptors_id_key
    end
    
    create_table(:attribute_authority_descriptors) do
      primary_key :id, :type=>"int(11)"
      foreign_key :entity_descriptor_id, :entity_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:entity_descriptor_id], :name=>:ed_aad_fkey
    end
    
    create_table(:ca_key_infos) do
      primary_key :id, :type=>"int(11)"
      foreign_key :metadata_instance_id, :metadata_instances, :type=>"int(11)", :key=>[:id]
      
      index [:metadata_instance_id], :name=>:ca_key_infos_mi_id_fk
    end
    
    create_table(:entity_attributes) do
      primary_key :id, :type=>"int(11)"
      foreign_key :entity_descriptor_id, :entity_descriptors, :type=>"int(11)", :key=>[:id]
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :metadata_instance_id, :metadata_instances, :type=>"int(11)", :key=>[:id]
      
      index [:entity_descriptor_id], :name=>:ea_entdesc_fkey
      index [:metadata_instance_id], :name=>:entity_attributes_mi_id_fk
    end
    
    create_table(:entity_ids) do
      primary_key :id, :type=>"int(11)"
      foreign_key :entity_descriptor_id, :entity_descriptors, :type=>"int(11)", :key=>[:id]
      column :sha1, "varchar(255)", :null=>false
      foreign_key :raw_entity_descriptor_id, :raw_entity_descriptors, :type=>"int(11)", :key=>[:id]
      foreign_key :entity_source_id, :entity_sources, :type=>"int(11)", :key=>[:id]
      
      index [:entity_descriptor_id], :name=>:eid_ed_fkey
      index [:entity_source_id, :sha1], :unique=>true
      index [:raw_entity_descriptor_id], :name=>:red_eid_fkey
    end
    
    create_table(:idp_sso_descriptors) do
      primary_key :id, :type=>"int(11)"
      column :want_authn_requests_signed, "tinyint(1)", :null=>false
      foreign_key :entity_descriptor_id, :entity_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:entity_descriptor_id], :name=>:ed_idp_fkey
    end
    
    create_table(:publication_infos) do
      primary_key :id, :type=>"int(11)"
      foreign_key :entity_descriptor_id, :entity_descriptors, :type=>"int(11)", :key=>[:id]
      column :publisher, "varchar(255)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :metadata_instance_id, :metadata_instances, :type=>"int(11)", :key=>[:id]
      
      index [:entity_descriptor_id], :name=>:pi_entdesc_fkey
      index [:metadata_instance_id], :name=>:publication_infos_mi_id_fk
    end
    
    create_table(:registration_infos) do
      primary_key :id, :type=>"int(11)"
      foreign_key :entity_descriptor_id, :entity_descriptors, :type=>"int(11)", :key=>[:id]
      column :registration_authority, "varchar(255)", :null=>false
      column :registration_instant, "datetime"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :metadata_instance_id, :metadata_instances, :type=>"int(11)", :key=>[:id]
      
      index [:metadata_instance_id], :name=>:registration_infos_mi_id_fk
      index [:entity_descriptor_id], :name=>:ri_entdesc_fkey
    end
    
    create_table(:role_descriptors) do
      primary_key :id, :type=>"int(11)"
      foreign_key :entity_descriptor_id, :entity_descriptors, :type=>"int(11)", :null=>false, :key=>[:id]
      foreign_key :organization_id, :organizations, :type=>"int(11)", :key=>[:id]
      column :error_url, "varchar(255)"
      column :extensions, "text"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      column :kind, "varchar(255)"
      column :enabled, "tinyint(1)", :default=>true
      
      index [:entity_descriptor_id], :name=>:ed_rd_key
      index [:organization_id], :name=>:o_rd_key
    end
    
    create_table(:sp_sso_descriptors) do
      primary_key :id, :type=>"int(11)"
      column :authn_requests_signed, "tinyint(1)", :null=>false
      column :want_assertions_signed, "tinyint(1)", :null=>false
      foreign_key :entity_descriptor_id, :entity_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:entity_descriptor_id], :name=>:ed_sp_fkey
    end
    
    create_table(:assertion_consumer_services) do
      primary_key :id, :type=>"int(11)"
      foreign_key :sp_sso_descriptor_id, :sp_sso_descriptors, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:sp_sso_descriptor_id], :name=>:sp_acs_fkey
    end
    
    create_table(:assertion_id_request_services) do
      primary_key :id, :type=>"int(11)"
      foreign_key :idp_sso_descriptor_id, :idp_sso_descriptors, :type=>"int(11)", :key=>[:id]
      foreign_key :attribute_authority_descriptor_id, :attribute_authority_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:attribute_authority_descriptor_id], :name=>:aad_aidrs_fkey
      index [:idp_sso_descriptor_id], :name=>:idp_aidr_fkey
    end
    
    create_table(:attribute_consuming_services) do
      primary_key :id, :type=>"int(11)"
      foreign_key :sp_sso_descriptor_id, :sp_sso_descriptors, :type=>"int(11)", :null=>false, :key=>[:id]
      column :index, "int(11)", :null=>false
      column :default, "tinyint(1)", :null=>false
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:sp_sso_descriptor_id], :name=>:sp_attrcs_fkey
    end
    
    create_table(:attribute_profiles) do
      primary_key :id, :type=>"int(11)"
      foreign_key :idp_sso_descriptor_id, :idp_sso_descriptors, :type=>"int(11)", :key=>[:id]
      foreign_key :attribute_authority_descriptor_id, :attribute_authority_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:attribute_authority_descriptor_id], :name=>:aad_ap_fkey
      index [:idp_sso_descriptor_id], :name=>:ap_idp_fkey
    end
    
    create_table(:attribute_services) do
      primary_key :id, :type=>"int(11)"
      foreign_key :attribute_authority_descriptor_id, :attribute_authority_descriptors, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:attribute_authority_descriptor_id], :name=>:aad_as_fkey
    end
    
    create_table(:attributes) do
      primary_key :id, :type=>"int(11)"
      column :name, "varchar(255)", :null=>false
      column :friendly_name, "varchar(255)"
      column :legacy_name, "varchar(255)"
      column :oid, "varchar(255)"
      column :description, "varchar(255)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :idp_sso_descriptor_id, :idp_sso_descriptors, :type=>"int(11)", :key=>[:id]
      foreign_key :attribute_authority_descriptor_id, :attribute_authority_descriptors, :type=>"int(11)", :key=>[:id]
      foreign_key :entity_attribute_id, :entity_attributes, :type=>"int(11)", :key=>[:id]
      
      index [:attribute_authority_descriptor_id], :name=>:aad_attr_fkey
      index [:entity_attribute_id], :name=>:ea_attr_fkey
      index [:idp_sso_descriptor_id], :name=>:idp_attr_fkey
    end
    
    create_table(:contact_people) do
      primary_key :id, :type=>"int(11)"
      foreign_key :contact_id, :contacts, :type=>"int(11)", :null=>false, :key=>[:id]
      column :contact_type_id, "int(11)", :null=>false
      column :extensions, "text"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :entity_descriptor_id, :entity_descriptors, :type=>"int(11)", :key=>[:id]
      foreign_key :role_descriptor_id, :role_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:contact_id], :name=>:contact_id_fkey
      index [:entity_descriptor_id], :name=>:ed_id_cp_fkey
      index [:role_descriptor_id], :name=>:rd_cp_fkey
    end
    
    create_table(:disco_hints) do
      primary_key :id, :type=>"int(11)"
      foreign_key :idp_sso_descriptor_id, :idp_sso_descriptors, :type=>"int(11)", :null=>false, :key=>[:id]
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:idp_sso_descriptor_id], :name=>:mdui_dh_idp_fkey
    end
    
    create_table(:discovery_response_services) do
      primary_key :id, :type=>"int(11)"
      foreign_key :sp_sso_descriptor_id, :sp_sso_descriptors, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:sp_sso_descriptor_id], :name=>:sp_drs_fkey
    end
    
    create_table(:key_descriptors) do
      primary_key :id, :type=>"int(11)"
      column :key_type_id, "int(11)"
      column :disabled, "tinyint(1)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :role_descriptor_id, :role_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:role_descriptor_id], :name=>:rd_kd_fkey
    end
    
    create_table(:name_id_formats) do
      primary_key :id, :type=>"int(11)"
      foreign_key :sso_descriptor_id, :sso_descriptors, :type=>"int(11)", :key=>[:id]
      foreign_key :attribute_authority_descriptor_id, :attribute_authority_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:attribute_authority_descriptor_id], :name=>:aad_nidf_fkey
      index [:sso_descriptor_id], :name=>:nidf_sso_fkey
    end
    
    create_table(:name_id_mapping_services) do
      primary_key :id, :type=>"int(11)"
      foreign_key :idp_sso_descriptor_id, :idp_sso_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:idp_sso_descriptor_id], :name=>:idp_nidms_fkey
    end
    
    create_table(:protocol_supports) do
      primary_key :id, :type=>"int(11)"
      foreign_key :role_descriptor_id, :role_descriptors, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:role_descriptor_id], :name=>:ps_rd_fkey
    end
    
    create_table(:registration_policies) do
      primary_key :id, :type=>"int(11)"
      foreign_key :registration_info_id, :registration_infos, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:registration_info_id], :name=>:rp_ri_fkey
    end
    
    create_table(:saml_uris) do
      primary_key :id, :type=>"int(11)"
      column :uri, "text", :null=>false
      column :description, "varchar(255)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :role_descriptor_id, :role_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:role_descriptor_id], :name=>:uri_descriptor_id_fkey
    end
    
    create_table(:scopes) do
      primary_key :id, :type=>"int(11)"
      foreign_key :role_descriptor_id, :role_descriptors, :type=>"int(11)", :null=>false, :key=>[:id]
      column :value, "varchar(255)", :null=>false
      column :regexp, "tinyint(1)", :default=>false, :null=>false
      column :created_at, "datetime", :null=>false
      column :updated_at, "datetime", :null=>false
      column :locked, "tinyint(1)", :default=>false, :null=>false
      
      index [:role_descriptor_id], :name=>:scope_rd_fkey
    end
    
    create_table(:single_sign_on_services) do
      primary_key :id, :type=>"int(11)"
      foreign_key :idp_sso_descriptor_id, :idp_sso_descriptors, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:idp_sso_descriptor_id], :name=>:idp_ssos_fkey
    end
    
    create_table(:sirtfi_contact_people) do
      primary_key :id, :type=>"int(11)"
      foreign_key :contact_id, :contacts, :type=>"int(11)", :null=>false, :key=>[:id]
      foreign_key :entity_descriptor_id, :entity_descriptors, :type=>"int(11)", :key=>[:id]
      foreign_key :role_descriptor_id, :role_descriptors, :type=>"int(11)", :key=>[:id]
      column :extensions, "text"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:contact_id], :name=>:sirtfi_contact_fkey
      index [:entity_descriptor_id], :name=>:sirtfi_ed_cp_fkey
      index [:role_descriptor_id], :name=>:sirtfi_rd_cp_fkey
    end
    
    create_table(:ui_infos) do
      primary_key :id, :type=>"int(11)"
      foreign_key :role_descriptor_id, :role_descriptors, :type=>"int(11)", :null=>false, :key=>[:id]
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:role_descriptor_id], :name=>:mdui_ui_rd_fkey
    end
    
    create_table(:usage_policies) do
      primary_key :id, :type=>"int(11)"
      foreign_key :publication_info_id, :publication_infos, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:publication_info_id], :name=>:up_pi_fkey
    end
    
    create_table(:attribute_values) do
      primary_key :id, :type=>"int(11)"
      foreign_key :attribute_id, :attributes, :type=>"int(11)", :null=>false, :key=>[:id]
      column :value, "varchar(255)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:attribute_id], :name=>:attribute_av_fkey
    end
    
    create_table(:descriptions) do
      primary_key :id, :type=>"int(11)"
      foreign_key :ui_info_id, :ui_infos, :type=>"int(11)", :key=>[:id]
      
      index [:ui_info_id], :name=>:des_ui_info_fkey
    end
    
    create_table(:display_names) do
      primary_key :id, :type=>"int(11)"
      foreign_key :ui_info_id, :ui_infos, :type=>"int(11)", :key=>[:id]
      
      index [:ui_info_id], :name=>:dn_ui_info_fkey
    end
    
    create_table(:domain_hints) do
      primary_key :id, :type=>"int(11)"
      foreign_key :disco_hints_id, :disco_hints, :type=>"int(11)", :key=>[:id]
      column :domain, "varchar(255)", :null=>false
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:disco_hints_id], :name=>:dom_disco_hints_fkey
    end
    
    create_table(:encryption_methods) do
      primary_key :id, :type=>"int(11)"
      column :algorithm, "varchar(255)", :null=>false
      column :key_size, "varchar(255)"
      column :oae_params, "varchar(255)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :key_descriptor_id, :key_descriptors, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:key_descriptor_id], :name=>:key_descriptors_enc_fkey
    end
    
    create_table(:geolocation_hints) do
      primary_key :id, :type=>"int(11)"
      foreign_key :disco_hints_id, :disco_hints, :type=>"int(11)", :key=>[:id]
      column :uri, "varchar(255)", :null=>false
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:disco_hints_id], :name=>:geo_disco_hints_fkey
    end
    
    create_table(:information_urls) do
      primary_key :id, :type=>"int(11)"
      foreign_key :ui_info_id, :ui_infos, :type=>"int(11)", :key=>[:id]
      
      index [:ui_info_id], :name=>:infourl_ui_info_fkey
    end
    
    create_table(:ip_hints) do
      primary_key :id, :type=>"int(11)"
      foreign_key :disco_hints_id, :disco_hints, :type=>"int(11)", :key=>[:id]
      column :block, "varchar(255)", :null=>false
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:disco_hints_id], :name=>:ip_disco_hints_fkey
    end
    
    create_table(:key_infos) do
      primary_key :id, :type=>"int(11)"
      column :data, "text", :null=>false
      column :subject, "varchar(2048)"
      column :issuer, "varchar(2048)"
      column :key_name, "varchar(255)"
      column :expiry, "datetime"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :key_descriptor_id, :key_descriptors, :type=>"int(11)", :key=>[:id]
      
      index [:key_descriptor_id], :name=>:key_descriptor_id
    end
    
    create_table(:keyword_lists) do
      primary_key :id, :type=>"int(11)"
      foreign_key :ui_info_id, :ui_infos, :type=>"int(11)", :key=>[:id]
      column :lang, "varchar(255)"
      column :content, "text"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:ui_info_id], :name=>:keyl_ui_info_fkey
    end
    
    create_table(:logos) do
      primary_key :id, :type=>"int(11)"
      foreign_key :ui_info_id, :ui_infos, :type=>"int(11)", :key=>[:id]
      column :uri, "text", :null=>false
      column :lang, "varchar(255)"
      column :width, "int(11)"
      column :height, "int(11)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      
      index [:ui_info_id], :name=>:logo_ui_info_fkey
    end
    
    create_table(:name_formats) do
      primary_key :id, :type=>"int(11)"
      foreign_key :attribute_id, :attributes, :type=>"int(11)", :key=>[:id]
      
      index [:attribute_id], :name=>:nf_attr_fkey
    end
    
    create_table(:privacy_statement_urls) do
      primary_key :id, :type=>"int(11)"
      foreign_key :ui_info_id, :ui_infos, :type=>"int(11)", :key=>[:id]
      
      index [:ui_info_id], :name=>:privurl_ui_info_fkey
    end
    
    create_table(:requested_attributes) do
      primary_key :id, :type=>"int(11)"
      column :reasoning, "varchar(255)", :null=>false
      column :required, "tinyint(1)", :null=>false
      column :approved, "tinyint(1)"
      column :created_at, "datetime"
      column :updated_at, "datetime"
      foreign_key :attribute_consuming_service_id, :attribute_consuming_services, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:attribute_consuming_service_id], :name=>:attrcs_ra_fkey
    end
    
    create_table(:service_descriptions) do
      primary_key :id, :type=>"int(11)"
      foreign_key :attribute_consuming_service_id, :attribute_consuming_services, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:attribute_consuming_service_id], :name=>:acs_sd_ln_fkey
    end
    
    create_table(:service_names) do
      primary_key :id, :type=>"int(11)"
      foreign_key :attribute_consuming_service_id, :attribute_consuming_services, :type=>"int(11)", :null=>false, :key=>[:id]
      
      index [:attribute_consuming_service_id], :name=>:acs_sn_ln_fkey
    end
  end
end
              Sequel.migration do
                change do
                  self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140818053306_create_endpoints.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140818234240_create_indexed_endpoints.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140822005028_create_assertion_id_request_services.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140822005311_create_attribute_services.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140822005524_create_authz_services.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140822005536_create_manage_name_id_services.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140822005558_create_name_id_mapping_services.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140822005609_create_single_logout_services.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140822005621_create_single_sign_on_services.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140822005638_create_artifact_resolution_services.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140822005656_create_assertion_consumer_services.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140822005711_create_discovery_response_services.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140822031543_create_saml_uris.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140901052651_create_additional_metadata_locations.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140903010608_create_attributes.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140903011708_create_attribute_values.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140904004949_create_requested_attributes.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140904052630_create_ca_key_infos.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140908032428_create_key_infos.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140908225337_create_encryption_methods.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140908235114_create_key_descriptors.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140909005102_add_key_descriptor_foreign_key_to_encryption_method.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140910011808_create_contacts.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140910024454_create_contact_people.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140910045450_create_organizations.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140910052947_create_entities_descriptors.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140910054604_create_entity_descriptors.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140910054700_create_entity_ids.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140910232552_add_entity_descriptor_foreign_key_to_additional_metadata_locations.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140910233606_add_entity_descriptor_foreign_key_to_contact_people.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140911004429_create_role_descriptors.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140911005408_add_role_descriptor_foreign_key_to_key_descriptor.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140911005511_add_role_descriptor_foreign_key_to_contact_person.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140911025005_create_sso_descriptors.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140911025316_add_sso_descriptor_foreign_key_to_artifact_resolution_service.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140911044906_add_sso_descriptor_foreign_key_to_single_logout_service.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140911045122_add_sso_descriptor_foreign_key_to_manage_name_id_service.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140911045706_add_descriptor_foreign_key_to_saml_uri.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140924020619_create_idp_sso_descriptors.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140924021644_add_idp_sso_descriptor_foreign_key_to_single_sign_on_service.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140924041941_add_idp_sso_descriptor_foreign_key_to_name_id_mapping_service.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140924051829_add_idp_sso_descriptor_foreign_key_to_assertion_id_request_service.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140925015857_add_idp_sso_descriptor_foreign_key_to_attribute.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140925040205_create_sp_sso_descriptors.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140925043234_add_sp_sso_descriptor_foreign_key_to_assertion_consumer_service.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140926014310_create_attribute_consuming_services.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140926014915_create_localized_names.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140926032216_add_assertion_consumer_service_foreign_key_to_requested_attribute.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140926040234_create_service_names.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140926041237_create_service_descriptions.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140926044821_alter_organization_to_drop_name_columns.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140926045318_create_organization_names.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140928232726_create_organiation_display_names.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140929001858_create_localized_uris.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140929011857_create_organization_urls.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140929105127_drop_type_from_saml_uri.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20140929222759_create_protocol_supports.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141003031946_create_name_id_formats.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141003034807_create_attribute_profiles.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141003041456_create_name_formats.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141009013820_create_attribute_authority_descriptors.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141009233538_add_attribute_authority_descriptor_foreign_key_to_attribute_service.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141010012208_add_attribute_authority_descriptor_foreign_key_to_assertion_id_request_service.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141020231401_add_attribute_authority_descriptor_foreign_key_to_name_id_format.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141021004610_add_attribute_authority_descriptor_foreign_key_to_attribute_profile.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141021010219_add_attribute_authority_descriptor_foreign_key_to_attribute.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141107022909_create_mdui_ui_infos.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141117022213_create_mdui_display_names.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141124035915_create_mdui_descriptions.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141124050655_create_mdui_keywords.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141125004103_create_mdui_logos.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141125012915_create_mdui_information_urls.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141125015350_create_mdui_privacy_statement_urls.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141125034516_create_mdui_disco_hints.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141125043639_create_mdui_ip_hints.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141125044914_create_mdui_domain_hints.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141125045756_create_mdui_geolocation_hints.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141126233918_create_mdrpi_registration_infos.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141127010924_create_mdrpi_registration_policies.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141127022054_create_mdrpi_publication_infos.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141127031000_create_mdrpi_usage_policies.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141130223957_create_mdattr_entity_attributes.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141201035241_add_entity_attribute_to_attribute.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141202034305_add_entity_descriptor_to_sp_sso_descriptor.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141202045814_add_entity_descriptor_to_idp_sso_descriptor.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141202051116_add_entity_descriptor_to_attribute_authority_descriptor.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141212022130_create_api_subjects.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141215022306_create_roles.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141215034636_create_permissions.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20141215043512_join_api_subjects_to_roles.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150105231504_create_subjects.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150105234007_join_subjects_to_roles.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150108055454_add_self_reference_to_entities_descriptor.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150109010735_add_entities_descriptor_foreign_key_to_ca_key_infos.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150109011330_add_ca_verify_depth_to_entities_descriptor.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150212012240_create_tags.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150213002521_add_unique_constraints_to_tag.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150216031859_rename_entities_descriptor_to_metadata_instance.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150216035106_create_entity_sources.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150216043207_create_known_entities.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150216050609_rename_entities_descriptor_id_foreign_keys.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150217053637_add_kind_to_role_descriptor.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150219021123_create_raw_entity_descriptors.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150223223047_add_url_to_entity_source.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150226001416_add_sp_sso_descriptor_foreign_key_to_discovery_response_services.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150226030540_add_certificate_to_entity_sources.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150304031737_add_hash_algorithm_to_metadata_instance.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150305210958_create_keypairs.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150305230517_add_keypair_to_metadata_instances.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150310004339_create_federation_registry_sources.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150312002156_create_federation_registry_objects.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150415004025_add_enabled_to_entity_descriptor.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150415030131_add_enabled_to_raw_entity_descriptor.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150504231555_add_primary_tag_to_metadata_instance.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150504232739_add_all_entities_to_metadata_instance.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150505032956_add_saml_fields_to_metadata_instance.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150505052005_drop_entity_descriptor_from_tags.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150505052251_add_known_entity_foreign_key_to_tags.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150703014627_add_sha1_to_entity_id.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150703023921_add_raw_entity_descriptor_foreign_key_to_entity_id.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150703030108_update_entity_descriptor_foreign_key_on_entity_id.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150708025727_remove_entity_id_from_known_entity.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150803035704_drop_url_from_organization.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150902054540_add_registration_authority_to_federation_registry_source.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150902055324_add_registration_policy_to_federation_registry_source.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150904024225_rename_federation_registry_object_fields.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20150907002959_create_shibmd_scopes.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20151029042723_add_enabled_to_role_descriptors.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20151116230223_add_fingerprint_to_keypairs.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20151117041822_add_unique_key_to_metadata_instance_primary_tag.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20151123000127_alter_kd_to_ki_relationship.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20151202040537_remove_role_descriptor_from_tags.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20151203020409_add_timestamps_to_keypair.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20151203023101_remove_active_from_role_descriptor.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20151203025816_rename_active_to_enabled.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20151204023033_add_flags_to_raw_entity_descriptors.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20151217044855_add_cache_period_to_metadata_instance.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20160114033904_change_raw_entity_descriptor_xml_to_medium_text.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20160203023734_add_source_tag_to_entity_source.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20160209223646_remove_source_tag_default_value.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20160314045620_set_correct_encoding_collation.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20160316030021_change_collation_to_binary.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20160530102028_api_subject_unique_x509.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20160711003010_add_entity_source_id_to_entity_ids.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20160920023804_rename_primary_tag_to_identifier_in_metadata_instance.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20160920024949_add_primary_tag_to_metadata_instances.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20170616045451_add_derived_flag_to_tags.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20170619194544_create_derived_tags.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20170802213241_make_key_type_id_nullable.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20170802230844_allow_larger_rank_values.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20170803002700_create_sirtfi_contact_people.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20190225092700_alter_localized_names.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20190320095000_alter_key_subject_issuer.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20191203011131_add_fixed_boolean_to_shibmd_scope.rb')"
self << "INSERT INTO `schema_migrations` (`filename`) VALUES ('20200324034550_add_token_to_api_subjects.rb')"
                end
              end
