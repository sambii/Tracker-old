# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Counselor < User
  default_scope where(counselor: true)

  # Relationships
  belongs_to                    :school

  # Validations
  validates_presence_of         :first_name,
                                :last_name,
                                :school_id
end
