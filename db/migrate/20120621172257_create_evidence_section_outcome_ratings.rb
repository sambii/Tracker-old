class CreateEvidenceSectionOutcomeRatings < ActiveRecord::Migration
  def change
    create_table :evidence_section_outcome_ratings do |t|
      t.integer :evidence_id
      t.integer :section_outcome_id
      t.string :rating
      t.string :comment

      t.timestamps
    end
  end
end
