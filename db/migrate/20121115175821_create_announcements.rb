class CreateAnnouncements < ActiveRecord::Migration
  def change
    create_table :announcements do |t|
      t.text :content
      t.boolean :restrict_to_staff, default: false
      t.datetime :start_at
      t.datetime :end_at
      t.timestamps
    end
  end
end
