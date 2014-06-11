class CreateMembership < ActiveRecord::Migration
  def change
    create_table :membership do |table|
      table.integer :user_id, null: false
      table.integer :meetup_id, null: false
    end
  end
end
