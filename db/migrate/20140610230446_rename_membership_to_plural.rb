class RenameMembershipToPlural < ActiveRecord::Migration
  def change
    rename_table :membership, :memberships
  end
end
