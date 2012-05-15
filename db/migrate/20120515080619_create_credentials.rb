class CreateCredentials < ActiveRecord::Migration
  def change
    create_table :credentials do |c|
      c.references :user
      c.references :place
      c.string :document_type
    end
    add_index :credentials, [:user_id, :place_id, :document_type], :unique => true
  end
end
