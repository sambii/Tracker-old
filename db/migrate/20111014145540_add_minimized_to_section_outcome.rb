class AddMinimizedToSectionOutcome < ActiveRecord::Migration
  def self.up
    add_column :section_outcomes, :minimized, :boolean, :default => false
  end

  def self.down
    remove_column :section_outcomes, :minimized
  end
end
