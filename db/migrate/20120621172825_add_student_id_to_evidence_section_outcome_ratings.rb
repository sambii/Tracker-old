class AddStudentIdToEvidenceSectionOutcomeRatings < ActiveRecord::Migration
  def change
    add_column :evidence_section_outcome_ratings, :student_id, :integer
  end
end
