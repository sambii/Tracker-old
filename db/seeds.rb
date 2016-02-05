require 'io/console'

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# username = nil
# password = nil
# password_confirmation = nil

# puts "Please enter the system administrator's username: "
# username = STDIN.gets.chomp

# puts "Please enter the system administrator's password: "
# password = STDIN.noecho(&:gets).chomp

# puts "Please confirm the system administrator's password: "
# password_confirmation = STDIN.noecho(&:gets).chomp

# if password != password_confirmation
#   raise "Your passwords didn't match! Please try again. No data was seeded."
# end

# SystemAdministrator.create(
#   username: username,
#   password: password,
#   password_confirmation: password_confirmation
# )

#if SystemAdministrator.last == nil
#  raise "There was an error creating the system administrator!\n" +
#        "Make sure you've entered a valid username and password.\n" +
#        "No data was seeded."
#end

# SystemAdministrator.create(
#   username: 'deanna',
#   first_name: 'Deanna',
#   last_name: 'Daugherty',
#   email: 'ddaugherty@21pstem.org',
#   password: "password",
#   password_confirmation: "password"
# )

# SystemAdministrator.create(
#   username: 'dave',
#   first_name: 'Dave',
#   last_name: 'Taylor',
#   email: 'dtaylor@21pstem.org',
#   password: "password",
#   password_confirmation: "password"
# )

# Researcher.create(
#   username: 'researcher1',
#   first_name: 'Researcher fname 1',
#   last_name: 'Researcher lname 1',
#   researcher: true,
#   password: "password",
#   password_confirmation: "password"
# )

# Create model school first, so its ID is 1
# this is used for preventing students and parents in model school from changing passwords.
# see app/models/ability.rb
School.create(
  name: 'Model School',
  acronym: 'MOD',
  marking_periods: '2',
  city: 'Cairo',
  flags: 'use_family_name,user_by_first,grade_in_subject_name'
)

# Create training school first, so its ID is 2
School.create(
  name: 'Stem Egypt Training High School',
  acronym: 'ETH',
  marking_periods: '2',
  city: 'Cairo',
  flags: 'use_family_name,user_by_first,grade_in_subject_name'
)
