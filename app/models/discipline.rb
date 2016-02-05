# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Discipline < ActiveRecord::Base
  # Access Control
  # using_access_control

  # Callbacks

  # Relationships
  has_many                    :subjects
  has_many                    :teaching_resources

  # Validations
  validates_presence_of       :name
  validates_uniqueness_of     :name

  # Other Definitions
  def self.include_teaching_resources
    return_value = self.includes(:teaching_resources).order(
      :name,
      {
        :teaching_resources => :title
      }
    )
    return_value.each { |a| a.teaching_resources.sort! { |b,c| b.title <=> c.title } }
    return_value
  end
end
