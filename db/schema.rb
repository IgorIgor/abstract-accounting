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

ActiveRecord::Schema.define(:version => 20120111125823) do

  create_table "assets", :force => true do |t|
    t.string "tag"
  end

  add_index "assets", ["tag"], :name => "index_assets_on_tag", :unique => true

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
  end

  add_index "bo_ms", ["resource_id"], :name => "index_bo_ms_on_resource_id"

  create_table "charts", :force => true do |t|
    t.integer "currency_id"
  end

  create_table "deals", :force => true do |t|
    t.string  "tag"
    t.float   "rate"
    t.integer "entity_id"
    t.integer "give_id"
    t.string  "give_type"
    t.integer "take_id"
    t.string  "take_type"
    t.boolean "isOffBalance", :default => false
  end

  add_index "deals", ["entity_id", "tag"], :name => "index_deals_on_entity_id_and_tag", :unique => true

  create_table "detailed_assets", :force => true do |t|
    t.string  "tag"
    t.string  "brand"
    t.integer "mu_id"
    t.integer "manufacturer_id"
  end

  add_index "detailed_assets", ["manufacturer_id"], :name => "index_detailed_assets_on_manufacturer_id"
  add_index "detailed_assets", ["mu_id"], :name => "index_detailed_assets_on_mu_id"
  add_index "detailed_assets", ["tag", "brand", "mu_id"], :name => "index_detailed_assets_on_tag_and_brand_and_mu_id", :unique => true

  create_table "entities", :force => true do |t|
    t.string "tag"
  end

  create_table "estimate_elements", :force => true do |t|
    t.integer "estimate_id"
    t.integer "bom_id"
    t.float   "amount"
  end

  add_index "estimate_elements", ["bom_id"], :name => "index_estimate_elements_on_bom_id"
  add_index "estimate_elements", ["estimate_id"], :name => "index_estimate_elements_on_estimate_id"

  create_table "estimates", :force => true do |t|
    t.integer "entity_id"
    t.integer "price_list_id"
    t.integer "deal_id"
  end

  add_index "estimates", ["deal_id"], :name => "index_estimates_on_deal_id"
  add_index "estimates", ["entity_id"], :name => "index_estimates_on_entity_id"
  add_index "estimates", ["price_list_id"], :name => "index_estimates_on_price_list_id"

  create_table "facts", :force => true do |t|
    t.datetime "day"
    t.float    "amount"
    t.integer  "from_deal_id"
    t.integer  "to_deal_id"
    t.integer  "resource_id"
    t.string   "resource_type"
  end

  create_table "incomes", :force => true do |t|
    t.datetime "start"
    t.string   "side"
    t.float    "value"
    t.datetime "paid"
  end

  add_index "incomes", ["start"], :name => "index_incomes_on_start", :unique => true

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

  create_table "price_lists", :force => true do |t|
    t.integer  "resource_id"
    t.datetime "date"
  end

  add_index "price_lists", ["resource_id"], :name => "index_price_lists_on_resource_id"

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

  create_table "states", :force => true do |t|
    t.integer  "deal_id"
    t.string   "side"
    t.float    "amount"
    t.datetime "start"
    t.datetime "paid"
  end

  create_table "txns", :force => true do |t|
    t.integer "fact_id"
    t.float   "value"
    t.integer "status"
    t.float   "earnings"
  end

  add_index "txns", ["fact_id"], :name => "index_txns_on_fact_id", :unique => true

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

end
