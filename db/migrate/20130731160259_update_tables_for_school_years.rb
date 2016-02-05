class UpdateTablesForSchoolYears < ActiveRecord::Migration
  def self.up
    add_column :sections, :school_year_id, :integer
    add_column :schools, :school_year_id, :integer
    remove_column :sections, :year
  end

  def self.down
    remove_column :sections, :school_year_id
    remove_column :schools, :school_year_id
    add_column :sections, :year, :integer
  end
end