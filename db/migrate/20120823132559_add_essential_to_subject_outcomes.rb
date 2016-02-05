class AddEssentialToSubjectOutcomes < ActiveRecord::Migration
  def change
    add_column :subject_outcomes, :essential, :boolean, default: false
  end
end
