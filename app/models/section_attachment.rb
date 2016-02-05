# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SectionAttachment < ActiveRecord::Base
  # Access Control
  # using_access_control

  # Relationships
  belongs_to        :section
  has_attached_file :attachment

  # Validations
  validates_presence_of(
    :name,
    :section_id,
    :attachment_file_name,
    :attachment_content_type,
    :attachment_file_size
  )
end
