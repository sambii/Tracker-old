class ManyToManyRolesImplementationPart1 < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.integer :user_id
      t.string  :entity_type    # Polymorphic; will contain names of other models,
      t.integer :entity_id      # i.e.) Teacher, Parent, Student, etc.
      t.timestamps
    end
  end

  def self.down
    drop_table :roles
  end
end
