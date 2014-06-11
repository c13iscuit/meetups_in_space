class AddComments < ActiveRecord::Migration
  def change
    create_table :comments do |table|
      table.string :title
      table.text :body, null: false
      table.integer :user_id, null: false
      table.integer :meetup_id, null: false

      table.timestamps
    end
  end
end
