class CreateSchoolAdministrators < ActiveRecord::Migration
  def self.up
    create_table :school_administrators do |t|
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :school_administrators
  end
end
