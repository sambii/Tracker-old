class AddSubjectIdToSection < ActiveRecord::Migration
  def self.up
    add_column :sections, :subject_id, :integer
  end

  def self.down
    remove_column :sections, :subject_id
  end
end
