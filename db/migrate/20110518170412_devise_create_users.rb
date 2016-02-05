class DeviseCreateUsers < ActiveRecord::Migration
  def self.up
    create_table(:users) do |t|
      # Begin Devise scaffold

      ## Database authenticatable
      t.string :email,              :null => false, :default => ""
      t.string :encrypted_password, :null => false, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      # End Devise scaffold

      t.string :username
      t.timestamps
    end

    # Begin Devise scaffold

    add_index :users, :email,                  :unique => true
    add_index :users, :reset_password_token,   :unique => true

    # End Devise scaffold
    add_index :users, :username,               :unique => true
  end

  def self.down
    drop_table :users
  end
end
