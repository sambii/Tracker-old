class AddMarkingPeriodToLo < ActiveRecord::Migration
  def change
    add_column :subject_outcomes, :marking_period, :integer
  end
end
