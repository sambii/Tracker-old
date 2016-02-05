class CreateSystemAdministrators < ActiveRecord::Migration
  def self.up
    create_table :system_administrators do |t|
      t.string :first_name
      t.string :last_name

      t.timestamps
    end
  end

  def self.down
    drop_table :system_administrators
  end
end
