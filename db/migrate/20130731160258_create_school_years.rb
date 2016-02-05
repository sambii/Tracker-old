class CreateSchoolYears < ActiveRecord::Migration
  def change
    create_table :school_years do |t|
      t.string :name
      t.integer :school_id
      t.date :starts_at
      t.date :ends_at

      t.timestamps
    end
  end
end
