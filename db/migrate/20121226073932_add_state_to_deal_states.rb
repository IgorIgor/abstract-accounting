class AddStateToDealStates < ActiveRecord::Migration
  def change
    add_column :deal_states, :state, :integer, :default => Statable::UNKNOWN
  end
end
