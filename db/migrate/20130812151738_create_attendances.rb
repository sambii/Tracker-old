class CreateAttendances < ActiveRecord::Migration
  def change
    create_table :attendances do |t|
      t.references :school
      t.references :subject
      t.references :section
      t.references :user
      t.references :school_year
      t.datetime :attendance_date
      t.references :excuse
      t.references :attendance_type

      t.timestamps
    end
    add_index :attendances, :school_id
    add_index :attendances, :subject_id
    add_index :attendances, :section_id
    add_index :attendances, :user_id
    add_index :attendances, :school_year_id
    add_index :attendances, :excuse_id
    add_index :attendances, :attendance_type_id
  end
end
