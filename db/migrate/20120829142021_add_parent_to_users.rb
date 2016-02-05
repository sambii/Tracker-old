class AddParentToUsers < ActiveRecord::Migration
  def change
    add_column :users, :parent, :boolean, default: false
  end
end
