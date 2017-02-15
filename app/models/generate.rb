# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
# generator.rb
class Generate
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :name, :subject_id, :subject_section_id, :grade_level, :section_id, :section_outcome_id, :student_id, :single_student_id, :marking_period, :start_date, :end_date, :details, :attendance_type_id, :user_type_staff, :user_type_students, :user_type_parents

  validates :name, presence: {message: I18n.translate('errors.cant_be_blank')}
  # validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  # validates_length_of :content, :maximum => 500
  validates_with GenerateValidator

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end
end
