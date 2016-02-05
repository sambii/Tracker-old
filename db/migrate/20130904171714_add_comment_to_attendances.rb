class AddCommentToAttendances < ActiveRecord::Migration
  def change
    add_column :attendances, :comment, :string, default: ''
  end
end
