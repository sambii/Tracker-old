class AddStreetAddressAndCityAndStateAndZipCodeToSchools < ActiveRecord::Migration
  def self.up
    add_column :schools, :street_address, :string
    add_column :schools, :city, :string
    add_column :schools, :state, :string
    add_column :schools, :zip_code, :string
  end

  def self.down
    remove_column :schools, :zip_code
    remove_column :schools, :state
    remove_column :schools, :city
    remove_column :schools, :street_address
  end
end
