class AddActiveToSectionOutcomes < ActiveRecord::Migration
  def self.up
    add_column :section_outcomes, :active, :boolean, :default => true
  end

  def self.down
    remove_column :section_outcomes, :active
  end
end
