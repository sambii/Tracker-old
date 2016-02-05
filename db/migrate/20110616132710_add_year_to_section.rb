class AddYearToSection < ActiveRecord::Migration
  def self.up
    add_column :sections, :year, :integer
  end

  def self.down
    remove_column :sections, :year
  end
end
