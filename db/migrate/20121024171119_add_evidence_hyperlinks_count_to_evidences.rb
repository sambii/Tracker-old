class AddEvidenceHyperlinksCountToEvidences < ActiveRecord::Migration
  def self.up
    add_column :evidences, :evidence_hyperlinks_count, :integer, default: 0
    
    Evidence.all.each do |evidence|
      evidence.evidence_hyperlinks_count = evidence.evidence_hyperlinks.length
      evidence.save
    end
  end

  def self.down
    remove_column :evidences, :evidence_hyperlinks_count
  end
end
