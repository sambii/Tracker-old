# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Excuse < ActiveRecord::Base
  belongs_to :school
  has_many :attendances

  attr_accessible :code, :description, :active

  validates :description, presence: {message: I18n.translate('errors.cant_be_blank')}
  validates :school_id, presence: {message: I18n.translate('errors.cant_be_blank')}

  # returns all valid excuses for an attendance record.
  # - it will include a deactivated record matching the ID passed.
  # - this is for select boxes so the attendance record can show deactivated items (if it was saved before deactivation).
  def self.valid_options(school_id, id)
    item = id.blank? ? nil : Excuse.find(id)
    active_recs = Excuse.where(school_id: school_id, active: true)
    active_recs << item if item.present? && !item.active?
    return active_recs
  end

end
