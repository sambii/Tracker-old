# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#

class GenerateValidator < ActiveModel::Validator
  def validate(record)
    Rails.logger.debug("*** validate #{record.inspect.to_s}")
    case record.name
    when 'tracker_usage' then validate_tracker_usage(record)
    when 'ss_by_lo' then validate_ss_by_lo(record)
    when 'ss_by_stud' then validate_ss_by_stud(record)
    when 'nyp_by_stud' then validate_nyp_by_stud(record)
    when 'nyp_by_lo' then validate_nyp_by_lo(record)
    when 'student_info' then student_info_handout(record)
    when 'student_info_by_grade' then student_info_handout_by_grade(record)
    when 'progress_rpt_gen' then progress_rpt_gen(record)
    when 'proficiency_bars_by_student' then proficiency_bars(record)
    when 'proficiency_bars_by_subject' then proficiency_bars(record)
    when 'progress_meters_by_subject' then progress_meters(record)
    when 'report_cards' then report_cards(record)
    when 'account_activity' then account_activity(record)
    when 'section_attendance_xls' then section_attendance_xls(record)
    when 'attendance_report' then attendance_report(record)
    else
      record.errors[:name] = I18n.translate('errors.is_invalid')
    end
  end

  def validate_tracker_usage(record)
  end

  def validate_ss_by_lo(record)
    record.errors[:section_id] = I18n.translate('errors.is_required') if record.section_id.blank?
  end

  def validate_ss_by_stud(record)
    record.errors[:section_id] = I18n.translate('errors.is_required') if record.section_id.blank?
  end

  def validate_nyp_by_stud(record)
    record.errors[:section_id] = I18n.translate('errors.is_required') if record.section_id.blank?
  end

  def validate_nyp_by_lo(record)
    record.errors[:section_id] = I18n.translate('errors.is_required') if record.section_id.blank?
  end

  def student_info_handout(record)
    record.errors[:section_id] = I18n.translate('errors.is_required') if record.section_id.blank?
  end

  def student_info_handout_by_grade(record)
  end

  def progress_rpt_gen(record)
    record.errors[:section_id] = I18n.translate('errors.is_required') if record.section_id.blank?
  end

  def proficiency_bars(record)
  end

  def progress_meters(record)
  end

  def report_cards(record)
    record.errors[:grade_level] = I18n.translate('errors.is_required') if record.grade_level.blank?
  end

  def account_activity(record)
  end

  def section_attendance_xls(record)
  end

  def attendance_report(record)
    record.errors[:subject_id] = I18n.translate('errors.is_required') if record.subject_id.blank?
    record.errors[:start_date] = I18n.translate('errors.is_required') if record.start_date.blank?
    record.errors[:end_date] = I18n.translate('errors.is_required') if record.end_date.blank?
  end

end
