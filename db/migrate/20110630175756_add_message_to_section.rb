class AddMessageToSection < ActiveRecord::Migration
  def self.up
    add_column :sections, :message, :text
  end

  def self.down
    remove_column :sections, :message
  end
end
