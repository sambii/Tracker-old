class AddMarkingPeriodsToSchools < ActiveRecord::Migration
  def self.up
    add_column :schools, :marking_periods, :integer
  end

  def self.down
    remove_column :schools, :marking_periods
  end
end
