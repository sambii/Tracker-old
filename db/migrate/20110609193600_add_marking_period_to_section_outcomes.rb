class AddMarkingPeriodToSectionOutcomes < ActiveRecord::Migration
  def self.up
    add_column :section_outcomes, :marking_period, :integer
  end

  def self.down
    remove_column :section_outcomes, :marking_period
  end
end
