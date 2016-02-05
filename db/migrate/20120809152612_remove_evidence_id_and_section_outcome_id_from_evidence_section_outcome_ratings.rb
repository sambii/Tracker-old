class RemoveEvidenceIdAndSectionOutcomeIdFromEvidenceSectionOutcomeRatings < ActiveRecord::Migration
  def up
    remove_column :evidence_section_outcome_ratings, :evidence_id
    remove_column :evidence_section_outcome_ratings, :section_outcome_id
  end

  def down
    add_column :evidence_section_outcome_ratings, :evidence_id, :integer
    add_column :evidence_section_outcome_ratings, :section_outcome_id, :integer
  end
end
