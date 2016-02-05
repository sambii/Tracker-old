class AddTopLevelPostIdToPosts < ActiveRecord::Migration
  def self.up
    add_column :posts, :top_level_post_id, :integer
  end

  def self.down
    remove_column :posts, :top_level_post_id
  end
end
