class AddSubsectionToSchools < ActiveRecord::Migration
  def change
    add_column :schools, :subsection, :boolean, default: false
  end
end
