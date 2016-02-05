class AddLoCodeToSubjectOutcomes < ActiveRecord::Migration
  def change
    rename_column :subject_outcomes, :name, :description
    add_column :subject_outcomes, :lo_code, :string, default: ''
    add_column :subject_outcomes, :active, :boolean, default: true
  end
end
