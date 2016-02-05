class AddEvidenceAttachmentsCountToEvidences < ActiveRecord::Migration
  def self.up
    add_column :evidences, :evidence_attachments_count, :integer, default: 0

    Evidence.all.each do |evidence|
      evidence.evidence_attachments_count = evidence.evidence_attachments.length
      evidence.save
    end
  end

  def self.down
    remove_column :evidences, :evidence_attachments_count
  end
end