class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.integer :user_id
      t.integer :parent_id
      t.string :header
      t.text :body

      t.timestamps
    end
  end

  def self.down
    drop_table :posts
  end
end
