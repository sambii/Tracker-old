# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Attendance < ActiveRecord::Base
  belongs_to :school
  belongs_to :section
  belongs_to :student,
    foreign_key: :user_id  # for students and possibly other types of users.
  belongs_to :excuse
  belongs_to :attendance_type
  belongs_to :enrollment

  attr_accessible :user_id, :comment, :attendance_date, :attendance_type_id, :excuse_id

  validates :school, presence: {message: I18n.translate('errors.cant_be_blank')}
  # no validations for presence of section (will be nil for daily attendence)
  validates :student, presence: {message: I18n.translate('errors.cant_be_blank')}
  # validates :excuse, presence: true
  validates :attendance_type, presence: {message: I18n.translate('errors.cant_be_blank')}
  validates :attendance_date, presence: {message: I18n.translate('errors.cant_be_blank')}

  # may possibly be used in New UI for Attendance Report ( if looping by student say in section)
  def count_attendances(start_date, end_date)
    attendances = Attendances.where(subject_id: subject_id, start_date: start_date, end_date: end_date)
    return_value = Hash.new(0)
    AttendanceType.all.each do |at|
      return_value[at.id] = 0
    end
    attendances.each do |a|
      ad = a.attendance_date.to_date
      if ( ad >= start_date.to_date && ad <= end_date.to_date )
        return_value[a.attendance_type_id] += 1
      end
    end
    return_value
  end


end
