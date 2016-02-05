class AddFlaggedToEvidenceSectionOutcomeRating < ActiveRecord::Migration
  def change
    add_column :evidence_section_outcome_ratings, :flagged, :boolean, default: false
  end
end
