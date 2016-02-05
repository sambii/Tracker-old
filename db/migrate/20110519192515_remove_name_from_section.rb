class RemoveNameFromSection < ActiveRecord::Migration
  def self.up
    remove_column(:sections, :name)
  end

  def self.down
    add_column(:sections, :name, :string)
  end
end
