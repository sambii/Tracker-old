class AddSelectedMarkingPeriodToSections < ActiveRecord::Migration
  def self.up
    add_column :sections, :selected_marking_period, :integer
  end

  def self.down
    remove_column :sections, :selected_marking_period
  end
end
