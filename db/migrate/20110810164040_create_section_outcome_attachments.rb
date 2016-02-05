class CreateSectionOutcomeAttachments < ActiveRecord::Migration
  def self.up
    create_table :section_outcome_attachments do |t|
      t.string :name
      t.integer :section_outcome_id

      t.timestamps
    end
  end

  def self.down
    drop_table :section_outcome_attachments
  end
end
