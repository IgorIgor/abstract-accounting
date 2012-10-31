# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121106132405) do

  create_table "allocations", :force => true do |t|
    t.integer  "deal_id"
    t.datetime "created"
  end

  add_index "allocations", ["deal_id"], :name => "index_allocations_on_deal_id", :unique => true

  create_table "assets", :force => true do |t|
    t.string  "tag"
    t.integer "detail_id"
    t.string  "mu"
  end

  add_index "assets", ["detail_id"], :name => "index_assets_on_detail_id"
  add_index "assets", ["tag", "mu"], :name => "index_assets_on_tag_and_mu", :unique => true

  create_table "balances", :force => true do |t|
    t.integer  "deal_id"
    t.string   "side"
    t.float    "amount"
    t.float    "value"
    t.datetime "start"
    t.datetime "paid"
  end

  add_index "balances", ["deal_id", "start"], :name => "index_balances_on_deal_id_and_start", :unique => true

  create_table "bo_m_elements", :force => true do |t|
    t.integer "bom_id"
    t.integer "resource_id"
    t.float   "rate"
  end

  add_index "bo_m_elements", ["bom_id"], :name => "index_bo_m_elements_on_bom_id"
  add_index "bo_m_elements", ["resource_id"], :name => "index_bo_m_elements_on_resource_id"

  create_table "bo_ms", :force => true do |t|
    t.integer "resource_id"
    t.string  "tab"
  end

  add_index "bo_ms", ["resource_id"], :name => "index_bo_ms_on_resource_id"
  add_index "bo_ms", ["tab"], :name => "index_bo_ms_on_tab"

  create_table "bo_ms_catalogs", :id => false, :force => true do |t|
    t.integer "bo_m_id"
    t.integer "catalog_id"
  end

  add_index "bo_ms_catalogs", ["bo_m_id", "catalog_id"], :name => "index_bo_ms_catalogs_on_bo_m_id_and_catalog_id", :unique => true

  create_table "business_people", :force => true do |t|
    t.integer "country_id"
    t.integer "identifier_id"
    t.string  "identifier_type"
    t.integer "person_id"
  end

  add_index "business_people", ["country_id"], :name => "index_business_people_on_country_id"
  add_index "business_people", ["identifier_id", "identifier_type"], :name => "index_business_people_on_identifier_id_and_identifier_type"
  add_index "business_people", ["person_id"], :name => "index_business_people_on_person_id"

  create_table "catalogs", :force => true do |t|
    t.string  "tag"
    t.integer "parent_id"
  end

  add_index "catalogs", ["parent_id", "tag"], :name => "index_catalogs_on_parent_id_and_tag", :unique => true
  add_index "catalogs", ["parent_id"], :name => "index_catalogs_on_parent_id"

  create_table "catalogs_price_lists", :id => false, :force => true do |t|
    t.integer "catalog_id"
    t.integer "price_list_id"
  end

  add_index "catalogs_price_lists", ["catalog_id", "price_list_id"], :name => "index_catalogs_price_lists_on_catalog_id_and_price_list_id", :unique => true

  create_table "charts", :force => true do |t|
    t.integer "currency_id"
  end

  create_table "classifiers", :force => true do |t|
    t.string "tag"
  end

  add_index "classifiers", ["tag"], :name => "index_classifiers_on_tag", :unique => true

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "item_id"
    t.string   "item_type"
    t.text     "message"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "countries", :force => true do |t|
    t.string "tag"
  end

  add_index "countries", ["tag"], :name => "index_countries_on_tag", :unique => true

  create_table "credentials", :force => true do |t|
    t.integer "user_id"
    t.integer "place_id"
    t.string  "document_type"
  end

  add_index "credentials", ["user_id", "place_id", "document_type"], :name => "index_credentials_on_user_id_and_place_id_and_document_type", :unique => true

  create_table "deal_states", :force => true do |t|
    t.integer "deal_id"
    t.date    "opened"
    t.date    "closed"
  end

  add_index "deal_states", ["deal_id"], :name => "index_deal_states_on_deal_id", :unique => true

  create_table "deals", :force => true do |t|
    t.string  "tag"
    t.float   "rate"
    t.integer "entity_id"
    t.boolean "isOffBalance", :default => false
    t.string  "entity_type"
  end

  add_index "deals", ["entity_id", "entity_type", "tag"], :name => "index_deals_on_entity_id_and_entity_type_and_tag", :unique => true

  create_table "descriptions", :force => true do |t|
    t.text    "description"
    t.integer "item_id"
    t.string  "item_type"
  end

  add_index "descriptions", ["item_id", "item_type"], :name => "index_descriptions_on_item_id_and_item_type", :unique => true

  create_table "detailed_assets", :force => true do |t|
    t.string  "tag"
    t.string  "brand"
    t.integer "mu_id"
    t.integer "manufacturer_id"
  end

  add_index "detailed_assets", ["manufacturer_id"], :name => "index_detailed_assets_on_manufacturer_id"
  add_index "detailed_assets", ["mu_id"], :name => "index_detailed_assets_on_mu_id"
  add_index "detailed_assets", ["tag", "brand", "mu_id"], :name => "index_detailed_assets_on_tag_and_brand_and_mu_id", :unique => true

  create_table "detailed_services", :force => true do |t|
    t.string  "tag"
    t.integer "mu_id"
  end

  add_index "detailed_services", ["mu_id"], :name => "index_detailed_services_on_mu_id"
  add_index "detailed_services", ["tag"], :name => "index_detailed_services_on_tag", :unique => true

  create_table "entities", :force => true do |t|
    t.string  "tag"
    t.integer "detail_id"
  end

  add_index "entities", ["detail_id"], :name => "index_entities_on_detail_id"

  create_table "estimate_elements", :force => true do |t|
    t.integer "estimate_id"
    t.integer "bom_id"
    t.float   "amount"
  end

  add_index "estimate_elements", ["bom_id"], :name => "index_estimate_elements_on_bom_id"
  add_index "estimate_elements", ["estimate_id"], :name => "index_estimate_elements_on_estimate_id"

  create_table "estimates", :force => true do |t|
    t.integer  "catalog_id"
    t.integer  "deal_id"
    t.integer  "legal_entity_id"
    t.datetime "date"
  end

  add_index "estimates", ["catalog_id"], :name => "index_estimates_on_catalog_id"
  add_index "estimates", ["deal_id"], :name => "index_estimates_on_deal_id"
  add_index "estimates", ["legal_entity_id"], :name => "index_estimates_on_legal_entity_id"

  create_table "facts", :force => true do |t|
    t.datetime "day"
    t.float    "amount"
    t.integer  "from_deal_id"
    t.integer  "to_deal_id"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.integer  "parent_id"
  end

  add_index "facts", ["resource_id", "resource_type"], :name => "index_facts_on_resource_id_and_resource_type"

  create_table "groups", :force => true do |t|
    t.integer "manager_id"
    t.string  "tag"
  end

  create_table "groups_users", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "user_id"
  end

  add_index "groups_users", ["group_id", "user_id"], :name => "index_groups_users_on_group_id_and_user_id", :unique => true

  create_table "identity_documents", :force => true do |t|
    t.integer "country_id"
    t.string  "number"
    t.date    "date_of_issue"
    t.string  "authority"
    t.integer "person_id"
  end

  add_index "identity_documents", ["country_id"], :name => "index_identity_documents_on_country_id"
  add_index "identity_documents", ["number", "country_id"], :name => "index_identity_documents_on_number_and_country_id", :unique => true
  add_index "identity_documents", ["person_id"], :name => "index_identity_documents_on_person_id"

  create_table "incomes", :force => true do |t|
    t.datetime "start"
    t.string   "side"
    t.float    "value"
    t.datetime "paid"
  end

  add_index "incomes", ["start"], :name => "index_incomes_on_start", :unique => true

  create_table "legal_entities", :force => true do |t|
    t.string  "name"
    t.integer "country_id"
    t.string  "identifier_name"
    t.string  "identifier_value"
    t.integer "detail_id"
    t.string  "detail_type"
  end

  add_index "legal_entities", ["country_id"], :name => "index_legal_entities_on_country_id"
  add_index "legal_entities", ["detail_id"], :name => "index_legal_entities_on_detail_id"
  add_index "legal_entities", ["name", "country_id"], :name => "index_legal_entities_on_name_and_country_id", :unique => true

  create_table "limits", :force => true do |t|
    t.integer "deal_id"
    t.integer "side"
    t.float   "amount"
  end

  create_table "money", :force => true do |t|
    t.integer "num_code"
    t.string  "alpha_code"
  end

  add_index "money", ["alpha_code"], :name => "index_money_on_alpha_code", :unique => true
  add_index "money", ["num_code"], :name => "index_money_on_num_code", :unique => true

  create_table "mus", :force => true do |t|
    t.string "tag"
  end

  add_index "mus", ["tag"], :name => "index_mus_on_tag", :unique => true

  create_table "notifications", :force => true do |t|
    t.integer "user_id"
    t.boolean "looked"
  end

  create_table "organizations", :force => true do |t|
    t.string  "full_name"
    t.string  "short_name"
    t.integer "country_id"
    t.string  "address"
    t.integer "identifier_id"
    t.string  "identifier_type"
  end

  add_index "organizations", ["country_id"], :name => "index_organizations_on_country_id"
  add_index "organizations", ["identifier_id", "identifier_type"], :name => "index_organizations_on_identifier_id_and_identifier_type"

  create_table "people", :force => true do |t|
    t.string "first_name"
    t.string "second_name"
    t.date   "birthday"
    t.string "place_of_birth"
  end

  add_index "people", ["first_name", "second_name"], :name => "index_people_on_first_name_and_second_name", :unique => true

  create_table "places", :force => true do |t|
    t.string "tag"
  end

  create_table "price_lists", :force => true do |t|
    t.integer  "resource_id"
    t.datetime "date"
    t.string   "tab"
  end

  add_index "price_lists", ["resource_id"], :name => "index_price_lists_on_resource_id"
  add_index "price_lists", ["tab"], :name => "index_price_lists_on_tab"

  create_table "prices", :force => true do |t|
    t.integer "resource_id"
    t.float   "rate"
    t.integer "price_list_id"
  end

  add_index "prices", ["price_list_id"], :name => "index_prices_on_price_list_id"
  add_index "prices", ["resource_id"], :name => "index_prices_on_resource_id"

  create_table "quotes", :force => true do |t|
    t.integer  "money_id"
    t.datetime "day"
    t.float    "rate"
    t.float    "diff"
  end

  add_index "quotes", ["money_id", "day"], :name => "index_quotes_on_money_id_and_day", :unique => true

  create_table "rules", :force => true do |t|
    t.integer "deal_id"
    t.boolean "fact_side"
    t.boolean "change_side"
    t.float   "rate"
    t.string  "tag"
    t.integer "from_id"
    t.integer "to_id"
  end

  add_index "rules", ["deal_id"], :name => "index_rules_on_deal_id"
  add_index "rules", ["from_id"], :name => "index_rules_on_from_id"
  add_index "rules", ["to_id"], :name => "index_rules_on_to_id"

  create_table "services", :force => true do |t|
    t.string  "tag"
    t.string  "mu"
    t.integer "detailed_id"
  end

  add_index "services", ["detailed_id"], :name => "index_services_on_detailed_id"
  add_index "services", ["tag", "mu"], :name => "index_services_on_tag_and_mu", :unique => true

  create_table "states", :force => true do |t|
    t.integer  "deal_id"
    t.string   "side"
    t.float    "amount"
    t.datetime "start"
    t.datetime "paid"
  end

  add_index "states", ["deal_id", "start"], :name => "index_states_on_deal_id_and_start", :unique => true

  create_table "terms", :force => true do |t|
    t.integer "deal_id"
    t.boolean "side"
    t.integer "place_id"
    t.integer "resource_id"
    t.string  "resource_type"
    t.integer "type_id"
  end

  add_index "terms", ["deal_id", "side"], :name => "index_terms_on_deal_id_and_side", :unique => true
  add_index "terms", ["place_id"], :name => "index_terms_on_place_id"
  add_index "terms", ["resource_id"], :name => "index_terms_on_resource_id"
  add_index "terms", ["resource_type"], :name => "index_terms_on_resource_type"
  add_index "terms", ["type_id"], :name => "index_terms_on_type_id"

  create_table "txns", :force => true do |t|
    t.integer "fact_id"
    t.float   "value"
    t.integer "status"
    t.float   "earnings"
  end

  add_index "txns", ["fact_id"], :name => "index_txns_on_fact_id", :unique => true

  create_table "users", :force => true do |t|
    t.integer  "entity_id"
    t.string   "email"
    t.string   "crypted_password"
    t.string   "salt"
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.string   "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
  end

  add_index "users", ["entity_id", "email"], :name => "index_users_on_entity_id_and_email", :unique => true
  add_index "users", ["remember_me_token"], :name => "index_users_on_remember_me_token"

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

  create_table "waybills", :force => true do |t|
    t.string   "document_id"
    t.integer  "deal_id"
    t.datetime "created"
  end

  add_index "waybills", ["deal_id"], :name => "index_waybills_on_deal_id", :unique => true

end
