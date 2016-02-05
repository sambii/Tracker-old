class AddPositionToEvidenceSectionOutcomes < ActiveRecord::Migration
  def change
    add_column :evidence_section_outcomes, :position, :integer
  end
end
