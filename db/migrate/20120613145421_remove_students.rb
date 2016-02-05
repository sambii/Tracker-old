class RemoveStudents < ActiveRecord::Migration
  def up
    drop_table :students
  end

  def down
    create_table :students do |t|
      t.string :gender
      t.integer :grade_level
      t.integer :school_id

      t.timestamps
    end
  end
end
