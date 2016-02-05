class CreateResearchers < ActiveRecord::Migration
  def self.up
    create_table :researchers do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :researchers
  end
end
