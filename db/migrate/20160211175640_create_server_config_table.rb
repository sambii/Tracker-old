class CreateServerConfigTable < ActiveRecord::Migration
  def change
    create_table :server_configs do |t|
      t.string :district_id, default: ''
      t.string :district_name, default: ''
      t.string :support_email, default: 'trackersupport@21pstem.org'
      t.string :support_team, default: 'Tracker Support Team'
      t.string :school_support_team, default: 'School IT Support Team'
      t.string :server_url, default: ''
      t.string :server_name, default: 'Tracker System'
      t.string :web_server_name, default: 'PARLO Tracker Web Server'
      t.timestamps null: false
    end
  end
end
