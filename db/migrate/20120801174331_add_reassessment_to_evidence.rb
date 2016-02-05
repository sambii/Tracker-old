class AddReassessmentToEvidence < ActiveRecord::Migration
  def change
    add_column :evidences, :reassessment, :boolean, default: false
  end
end
