class CreateSectionOutcomes < ActiveRecord::Migration
  def self.up
    create_table :section_outcomes do |t|
      t.integer :section_id
      t.integer :subject_outcome_id

      t.timestamps
    end
  end

  def self.down
    drop_table :section_outcomes
  end
end
