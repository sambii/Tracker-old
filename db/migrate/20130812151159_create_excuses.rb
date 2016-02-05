class CreateExcuses < ActiveRecord::Migration
  def change
    create_table :excuses do |t|
      t.references :school
      t.string :code
      t.string :description

      t.timestamps
    end
    add_index :excuses, :school_id
  end
end
