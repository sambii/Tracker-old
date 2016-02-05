class AddXidToUser < ActiveRecord::Migration
  def change
    add_column :users, :xid, :string
  end
end
