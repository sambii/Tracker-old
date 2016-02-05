class AddActiveToEvidence < ActiveRecord::Migration
  def self.up
    add_column :evidences, :active, :boolean, :default => true
  end

  def self.down
    remove_column :evidences, :active
  end
end
