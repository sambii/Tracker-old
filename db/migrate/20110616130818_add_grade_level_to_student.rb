class AddGradeLevelToStudent < ActiveRecord::Migration
  def self.up
    add_column :students, :grade_level, :integer
  end

  def self.down
    remove_column :students, :grade_level
  end
end
