class CreateAttendanceTypes < ActiveRecord::Migration
  def change
    create_table :attendance_types do |t|
      t.string :description

      t.timestamps
    end
  end
end
