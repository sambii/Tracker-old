class CreateSubjectOutcomes < ActiveRecord::Migration
  def self.up
    create_table :subject_outcomes do |t|
      t.string :name
      t.integer :position
      t.integer :subject_id

      t.timestamps
    end
  end

  def self.down
    drop_table :subject_outcomes
  end
end
