class AddPermissionsAndFlags < ActiveRecord::Migration
  def change
    add_column :schools, :flags, :string
    add_column :users, :permissions, :string
    add_column :users, :duties, :string
  end
end
