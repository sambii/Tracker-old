# Load the rails application
require File.expand_path('../application', __FILE__)

# Roles used in the application.
ROLES = [
  :system_administrator,
  :school_administrator,
  :researcher,
  :teacher, 
  :counselor,
  :student, 
  :parent
]

RACES = [
  "American Indian",
  "Asian / Pacific Islander",
  "Black",
  "Hispanic",
  "White",
  "Multi-Racial",
  "Other"
]

ALPHABET = %w(0 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)

# Initialize the rails application
Tracker2::Application.initialize!

LOCAL_TIME_ZONE = 'Eastern Time (US & Canada)'


