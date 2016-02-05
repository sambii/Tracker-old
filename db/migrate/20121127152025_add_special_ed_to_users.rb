class AddSpecialEdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :special_ed, :boolean, default: false
  end
end
