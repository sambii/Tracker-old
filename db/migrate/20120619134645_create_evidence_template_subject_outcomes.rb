class CreateEvidenceTemplateSubjectOutcomes < ActiveRecord::Migration
  def change
    create_table :evidence_template_subject_outcomes do |t|
      t.integer :evidence_template_id
      t.integer :subject_outcome_id

      t.timestamps
    end
  end
end
