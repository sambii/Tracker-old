class CreateEvidenceAttachments < ActiveRecord::Migration
  def self.up
    create_table :evidence_attachments do |t|
      t.string :name
      t.integer :evidence_id

      t.timestamps
    end
  end

  def self.down
    drop_table :evidence_attachments
  end
end
