class CreateSectionOutcomeRatings < ActiveRecord::Migration
  def self.up
    create_table :section_outcome_ratings do |t|
      t.string :rating
      t.integer :student_id
      t.integer :section_outcome_id

      t.timestamps
    end
  end

  def self.down
    drop_table :section_outcome_ratings
  end
end
