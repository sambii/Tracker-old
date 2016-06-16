# testing
class BulkLoSubjectSequencing < ActiveRecord::Migration
  def up
    add_column :subjects, :bulk_lo_seq_year, :string
    add_column :subjects, :bulk_lo_seq_timestamp, :timestamp
    add_column :subjects, :active, :boolean
    add_column :subject_outcomes, :model_lo_id, :integer
  end

  def down
    remove_column :subjects, :bulk_lo_seq_year
    remove_column :subjects, :bulk_lo_seq_timestamp
    remove_column :subjects, :active
    remove_column :subject_outcomes, :model_lo_id
  end
end
