class CreateEvidenceHyperlinks < ActiveRecord::Migration
  def change
    create_table :evidence_hyperlinks do |t|
      t.integer :evidence_id
      t.string :title
      t.string :hyperlink
      t.text :description

      t.timestamps
    end
  end
end
