class CreateEvidenceRatings < ActiveRecord::Migration
  def self.up
    create_table :evidence_ratings do |t|
      t.string :rating
      t.string :comment
      t.integer :student_id
      t.integer :evidence_id

      t.timestamps
    end
  end

  def self.down
    drop_table :evidence_ratings
  end
end
