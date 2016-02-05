class ManyToManyRolesImplementationPart4 < ActiveRecord::Migration
  def self.up
    remove_column     :students, :first_name
    remove_column     :students, :last_name
    remove_column     :teachers, :first_name
    remove_column     :teachers, :last_name
  end

  def self.down
    add_column        :students, :first_name, :string
    add_column        :students, :last_name,  :string
    add_column        :teachers, :first_name, :string
    add_column        :teachers, :last_name,  :string
  end
end
