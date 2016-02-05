class CreateSectionAttachments < ActiveRecord::Migration
  def self.up
    create_table :section_attachments do |t|
      t.integer :section_id
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :section_attachments
  end
end
