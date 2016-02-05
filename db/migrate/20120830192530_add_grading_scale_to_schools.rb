class AddGradingScaleToSchools < ActiveRecord::Migration
  def change
    add_column :schools, :grading_scale, :string
  end
end
