class CreateEvidenceSectionOutcomes < ActiveRecord::Migration
  def change
    create_table :evidence_section_outcomes do |t|
      t.integer :evidence_id
      t.integer :section_outcome_id

      t.timestamps
    end
  end
end
