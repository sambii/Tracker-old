class AddActiveToEnrollments < ActiveRecord::Migration
  def self.up
    add_column :enrollments, :active, :boolean, :default => true
  end

  def self.down
    remove_column :enrollments, :active
  end
end
