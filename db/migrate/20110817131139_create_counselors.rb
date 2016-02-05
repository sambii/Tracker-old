class CreateCounselors < ActiveRecord::Migration
  def self.up
    create_table :counselors do |t|
      t.string :first_name
      t.string :last_name
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :counselors
  end
end
