# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Announcement < ActiveRecord::Base
  attr_accessible :content, :end_at, :restrict_to_staff, :show_staff, :show_students_and_parents, :start_at

  scope :current, where("start_at <= :now and end_at >= :now", now: Time.zone.now)
  scope :unrestricted, where(restrict_to_staff: false)
  validates_presence_of :content, :start_at, :end_at

  def self.not_hidden(hidden_ids = nil)
    result = all
    result = where("id not in (?)", hidden_ids) if hidden_ids.present?
    result
  end
end
