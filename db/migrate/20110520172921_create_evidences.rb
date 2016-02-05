class CreateEvidences < ActiveRecord::Migration
  def self.up
    create_table :evidences do |t|
      t.string :name
      t.date :assignment_date
      t.integer :position
      t.integer :section_outcome_id

      t.timestamps
    end
  end

  def self.down
    drop_table :evidences
  end
end
