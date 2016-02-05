class AddPositionToSectionOutcome < ActiveRecord::Migration
  def self.up
    add_column :section_outcomes, :position, :integer
  end

  def self.down
    remove_column :section_outcomes, :position
  end
end
