# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
module StudentsHelper

  include ApplicationHelper

  # student bulk upload file column labels
  COL_SAMPLE = 'Sample'
  COL_SCHOOL = 'School'
  COL_SCH_NAME = 'School Name'
  COL_ACR = '* School Acronym'
  COL_ACR_NAME = 'school' # combined acronym and actual school name for report.
  COL_ID = '* Student ID'
  COL_ID_NOTE = '* Student ID  (must be unique)'
  COL_USERNAME = 'Username'
  COL_FNAME = '* Student First Name'
  COL_FAM_NAME = '* Student Family Name'
  COL_LAST_NAME = '* Student Last Name'
  COL_LNAME = 'lname' # family or last name (depending on which is supplied).
  COL_EMAIL = '* Student School Email'
  COL_GENDER = 'Gender'
  COL_GRADE = '* Grade Level'
  COL_PAR_USERNAME = 'Parent Username'
  COL_PAR_FNAME = 'Parent First Name'
  COL_PAR_FAM_NAME = 'Parent Family Name'
  COL_PAR_LAST_NAME = 'Parent Last Name'
  COL_PAR_LNAME = 'plname' # family or last name (depending on which is supplied).
  COL_PAR_EMAIL = 'Parent Email'
  COL_ERROR = 'error'
  COL_SUCCESS = 'success'
  COL_EMPTY = 'EMPTY'

  # student bulk upload file stage 2 processing
  def validate_csv_fields(csv_hash_in)
    csv_hash = csv_hash_in.clone
    begin
      if csv_hash[COL_SCHOOL]
        csv_hash[COL_SCH_NAME] = csv_hash[COL_SCHOOL]
      elsif csv_hash[COL_SCH_NAME]
        csv_hash[COL_SCHOOL] = csv_hash[COL_SCH_NAME]
      end
      if csv_hash[COL_ACR] == @school.acronym
        csv_hash[COL_ACR_NAME]= "#{@school.acronym} - #{@school.name}"
      else
        csv_hash[COL_ACR_NAME]= "#{csv_hash[COL_ACR]} - #{csv_hash[COL_SCH_NAME]}"
      end
      if csv_hash[COL_FAM_NAME]
        csv_hash[COL_LNAME] = csv_hash[COL_FAM_NAME]
      elsif csv_hash[COL_LAST_NAME]
        csv_hash[COL_LNAME] = csv_hash[COL_LAST_NAME]
      end
      if csv_hash[COL_PAR_FAM_NAME]
        csv_hash[COL_PAR_LNAME] = csv_hash[COL_PAR_FAM_NAME]
      elsif csv_hash[COL_PAR_LAST_NAME]
        csv_hash[COL_PAR_LNAME] = csv_hash[COL_PAR_LAST_NAME]
      end
      #
      if csv_hash[COL_ID_NOTE].blank? && csv_hash[COL_ID].blank?
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing Student ID')
      elsif csv_hash[COL_ID_NOTE].blank?
        csv_hash[COL_ID_NOTE] = csv_hash[COL_ID]
      else
        csv_hash[COL_ID] = csv_hash[COL_ID_NOTE]
      end
      if csv_hash[COL_ACR].blank? && csv_hash[COL_ID_NOTE].blank? && csv_hash[COL_FNAME].blank? && csv_hash[COL_LNAME].blank? && csv_hash[COL_EMAIL].blank? && csv_hash[COL_GRADE].blank?
        # blank row, set indicator
        csv_hash[COL_EMPTY] = true
      #
      elsif csv_hash[COL_SAMPLE].present?
        Rails.logger.debug("*** record is sample record")
        csv_hash[COL_EMPTY] = true
      else
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing School Acronym') if csv_hash[COL_ACR].blank?
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Not This School') if !csv_hash[COL_ACR].blank? && csv_hash[COL_ACR] != @school.acronym
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing Student First Name') if csv_hash[COL_FNAME].blank?
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing Student Last/Family Name') if csv_hash[COL_LNAME].blank?
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing Student Email') if csv_hash[COL_EMAIL].blank?
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing Grade Level') if csv_hash[COL_GRADE].blank?
      end
    rescue
      csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Error validating csv fields')
    end
    return csv_hash
  end

  # student bulk upload file stage 2 processing
  def validate_dup_emails(records)
    begin
      error_list = Hash.new
      records.each_with_index do |rx, ix|
        # check all records following it for duplicated email
        if error_list[ix+2] != '-1'
          records.drop(ix+1).each_with_index do |ry, iy|
            iyall = iy + ix + 1 # index of the later row being tested
            # check for duplicated student emails
            if error_list[iyall+2] != '-1' && rx[COL_EMAIL] == ry[COL_EMAIL]
              Rails.logger.debug("*** checking #{ix+2} - #{rx[COL_EMAIL]}, #{iyall+2} - #{ry[COL_EMAIL]} ")
              # put or add to end the list of duplicated lines, but only if not listed prior
              # note storing error_list as 2 relative line numbers for spreadsheet (zero relative to ignoring header line)
              error_list[ix+2] = (error_list[ix+2].present? ? error_list[ix+2] += ", #{iyall+2}" : "#{rx[COL_EMAIL]} at lines: #{ix+2}, #{iyall+2}")
              error_list[iyall+2] = '-1'
              # add the duplicate email message to this row, if not there already
              records[ix][COL_ERROR] = append_with_comma(records[ix][COL_ERROR], 'Duplicate Email') if !(records[ix][COL_ERROR] ||= '').include?('Duplicate Email')
              # add the duplicate email message to the later row, if not there already
              records[iyall][COL_ERROR] = append_with_comma(records[iyall][COL_ERROR], 'Duplicate Email') if !(records[iyall][COL_ERROR] ||= '').include?('Duplicate Email')
            end
          end
        end
      end
      Rails.logger.debug("*** error_list: #{error_list.inspect}")
      # remove lines matching lines removed with -1 value
      error_list.delete_if{|_,v| v == '-1'}
      Rails.logger.debug("*** cleaned error_list: #{error_list.inspect}")
      return {records: records, error_list: error_list, abort: false}
    rescue
      return {records: records, error_list: error_list, abort: true}
    end
  end

  # student bulk upload file stage 2 processing
  def validate_dup_xids(records)
    begin
      error_list = Hash.new
      records.each_with_index do |rx, ix|
        # check all records following it for duplicated student IDs
        if error_list[ix+2] != '-1'
          records.drop(ix+1).each_with_index do |ry, iy|
            iyall = iy + ix + 1 # index of the later row being tested
            # check for duplicated student IDs
            if error_list[iyall+2] != '-1' && rx[COL_ID] == ry[COL_ID]
              Rails.logger.debug("*** checking #{ix+2} - #{rx[COL_ID]}, #{iyall+2} - #{ry[COL_ID]} ")
              # put or add to end the list of duplicated lines, but only if not listed prior
              # note storing error_list as 2 relative line numbers for spreadsheet (zero relative to ignoring header line)
              error_list[ix+2] = (error_list[ix+2].present? ? error_list[ix+2] += ", #{iyall+2}" : "#{rx[COL_ID]} at lines: #{ix+2}, #{iyall+2}")
              error_list[iyall+2] = '-1'
              # add the duplicate student id message to this row, if not there already
              records[ix][COL_ERROR] = append_with_comma(records[ix][COL_ERROR], 'Duplicate Student ID') if !(records[ix][COL_ERROR] ||= '').include?('Duplicate Student ID')
              # add the duplicate email message to the later row, if not there already
              records[iyall][COL_ERROR] = append_with_comma(records[iyall][COL_ERROR], 'Duplicate Student ID') if !(records[iyall][COL_ERROR] ||= '').include?('Duplicate Student ID')
            end
          end
        end
      end
      Rails.logger.debug("*** error_list: #{error_list.inspect}")
      # remove lines matching lines removed with -1 value
      error_list.delete_if{|_,v| v == '-1'}
      Rails.logger.debug("*** cleaned error_list: #{error_list.inspect}")
      return {records: records, error_list: error_list, abort: false}
    rescue
    end
  end

  # student bulk upload file stage 4 and 5 processing
  def build_student(csv_hash)
    begin
      new_student = Student.new
      new_student.school_id = @school.id
      new_student.first_name = csv_hash[COL_FNAME]
      new_student.last_name = csv_hash[COL_LNAME]
      new_student.email = csv_hash[COL_EMAIL]
      new_student.xid = csv_hash[COL_ID_NOTE]
      new_student.grade_level = csv_hash[COL_GRADE]
      new_student.gender = csv_hash[COL_GENDER]
      # new_student.set_unique_username # Must be manually created (in transaction)
      new_student.set_temporary_password
    rescue
      new_student.errors.add(:base, 'build_student error')
    end
    return new_student
  end

  # build unique username from student fields and list of existing ones
  def build_unique_username(student, school, usernames)
    # student.set_unique_username, remove special characters and replace spaces with .
    initial_username = (school.acronym + "_" + student.first_name[0] + student.last_name).downcase.gsub(/[^0-9a-z -_\.]+/, '').gsub(/ /, '.')
    work_username = initial_username
    incr = 2
    until usernames[work_username] == nil
      work_username = initial_username+(incr.to_s)
      incr += 1
    end
    return work_username
  end

  # student bulk upload file stage 5 processing
  def build_parent(student, rx)
    begin
      # Update Parent fields
      parent = student.parent
      parent.first_name = rx[COL_PAR_FNAME] if rx[COL_PAR_FNAME]
      parent.last_name = rx[COL_PAR_LNAME] if rx[COL_PAR_LNAME]
      parent.email = rx[COL_PAR_EMAIL]
      parent.username = rx[COL_PAR_USERNAME]
    rescue
      parent.errors.add(:base, 'build_student error')
    end
    return parent
  end


end
