# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class TeachingResource < ActiveRecord::Base
  # Relationships
  belongs_to :discipline

  # Validations
  validates_presence_of     :title,
                            :url

  # Other
  def self.by_discipline
    self.joins(:discipline).order(
      {
        :disciplines => :name
      },
      :title
    )
  end

end
