class CreateEvidenceTemplates < ActiveRecord::Migration
  def change
    create_table :evidence_templates do |t|
      t.integer :subject_id
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
