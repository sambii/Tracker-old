class AddEvidenceSectionOutcomeIdToEvidenceSectionOutcomeRatings < ActiveRecord::Migration
  def change
    add_column :evidence_section_outcome_ratings, :evidence_section_outcome_id, :integer
  end
end
