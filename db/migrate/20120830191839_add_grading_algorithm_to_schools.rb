class AddGradingAlgorithmToSchools < ActiveRecord::Migration
  def change
    add_column :schools, :grading_algorithm, :string
  end
end
