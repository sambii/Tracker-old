# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SchoolAdministrator < User
  # using_access_control
  default_scope where(school_administrator: true)

  # Relationships
  belongs_to                    :school

  # Validations
  validates_presence_of         :school_id,:email
end
