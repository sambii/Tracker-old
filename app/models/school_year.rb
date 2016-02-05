# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SchoolYear < ActiveRecord::Base
  attr_accessible :ends_at, :name, :school_id, :starts_at, :school

  attr_reader :start_mm, :start_yyyy, :end_mm, :end_yyyy

  belongs_to        :school
  has_many          :sections

  validates_presence_of :school_id, :ends_at, :name, :starts_at
  validate :valid_dates

  def model_error
    I18n.translate('models.school_year.name')+' has error: '
  end

  def valid_dates
    if ends_at.present? and starts_at.present?
      errors.add(:end_date, model_error+I18n.translate('errors.end_date_before_start_date')) if ends_at < starts_at
    end
  end

  def date_in_school_year?(date_in)
    # strip out time from dates for valid compares
    begin
      date_work = date_in.to_date()
    rescue
      return false
    end
    if date_work < self.starts_at.to_date || date_work > self.ends_at.to_date
      return false
    else
      return true
    end
  end

  def start_yyyy
    self.starts_at.blank? ? '' : starts_at.strftime('%Y')
  end

  def start_mm
    self.starts_at.blank? ? '' : starts_at.strftime('%-m')
  end

  def end_yyyy
    self.ends_at.blank? ? '' : ends_at.strftime('%Y')
  end

  def end_mm
    self.ends_at.blank? ? '' : ends_at.strftime('%-m')
  end

end
