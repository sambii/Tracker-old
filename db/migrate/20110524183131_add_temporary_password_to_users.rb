class AddTemporaryPasswordToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :temporary_password, :string
  end

  def self.down
    remove_column :users, :temporary_password
  end
end
