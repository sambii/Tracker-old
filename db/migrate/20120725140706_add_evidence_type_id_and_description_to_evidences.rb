class AddEvidenceTypeIdAndDescriptionToEvidences < ActiveRecord::Migration
  def change
    add_column :evidences, :evidence_type_id, :integer
    add_column :evidences, :description, :string
    add_column :evidences, :section_id, :integer
  end
end
