# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
module UsersHelper

  include ApplicationHelper

  # staff file column labels
  COL_SAMPLE = 'Sample'
  COL_ID = 'Staff ID'
  COL_USERNAME = 'Username'
  COL_FNAME = '* First Name'
  COL_FAM_NAME = '* Family Name'
  COL_LAST_NAME = '* Last Name'
  COL_LNAME = 'lname' # extra hash item with the family or last name (depending on which is supplied).
  COL_SCHOOL = 'School'
  COL_SCH_NAME = 'School Name'
  COL_ACR = '* School Acronym'
  COL_ACR_NAME = 'school' # combined acronym and actual school name for report.
  COL_EMAIL = '* Email'
  COL_POSIT = '* Position'
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
      #
      if csv_hash[COL_ACR].blank? && csv_hash[COL_FNAME].blank? && csv_hash[COL_LNAME].blank? && csv_hash[COL_EMAIL].blank? && csv_hash[COL_POSIT].blank?
        # blank row, set indicator
        Rails.logger.debug("*** record is blank record")
        csv_hash[COL_EMPTY] = true
      #
      elsif csv_hash[COL_SAMPLE].present?
        Rails.logger.debug("*** record is sample record")
        csv_hash[COL_EMPTY] = true
      else
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing School Acronym') if csv_hash[COL_ACR].blank?
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Not This School') if !csv_hash[COL_ACR].blank? && csv_hash[COL_ACR] != @school.acronym
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing First Name') if csv_hash[COL_FNAME].blank?
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing Last/Family Name') if csv_hash[COL_LNAME].blank?
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing Email') if csv_hash[COL_EMAIL].blank?
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing position') if csv_hash[COL_POSIT].blank?
        Rails.logger.debug("*** csv_hash[COL_ERROR]: #{csv_hash[COL_ERROR]}")
      #
      end
    rescue StandardError => e
      csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], "Error validating csv fields: #{e.inspect}")
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
            # if later record has not been matched already, check if a match to current
            if error_list[iyall+2] != '-1' && rx[COL_EMAIL] == ry[COL_EMAIL]
              # put or add to end the list of duplicated lines, but only if not listed prior
              # ix+2 or iyall+2 for zero relative ruby arrays and ignoring the header line.
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
      return {records: records, error_list: error_list, abort: false}
    rescue StandardError => e
      return {records: records, error_list: error_list, abort: true}
    end
  end

  # staff bulk upload file stage 2 processing
  def validate_dup_xids(records)
    begin
      error_list = Hash.new
      records.each_with_index do |rx, ix|
        # check all records following it for duplicated student IDs
        if error_list[ix+2] != '-1'
          records.drop(ix+1).each_with_index do |ry, iy|
            iyall = iy + ix + 1 # index of the later row being tested
            # check for duplicated staff IDs
            if error_list[iyall+2] != '-1' && rx[COL_ID].present? && rx[COL_ID].present? && rx[COL_ID] == ry[COL_ID]
              Rails.logger.debug("*** checking #{ix+2} - #{rx[COL_ID]}, #{iyall+2} - #{ry[COL_ID]} ")
              # put or add to end the list of duplicated lines, but only if not listed prior
              # note storing error_list as 2 relative line numbers for spreadsheet (zero relative to ignoring header line)
              error_list[ix+2] = (error_list[ix+2].present? ? error_list[ix+2] += ", #{iyall+2}" : "#{rx[COL_ID]} at lines: #{ix+2}, #{iyall+2}")
              error_list[iyall+2] = '-1'
              # add the duplicate student id message to this row, if not there already
              records[ix][COL_ERROR] = append_with_comma(records[ix][COL_ERROR], 'Duplicate Staff ID') if !(records[ix][COL_ERROR] ||= '').include?('Duplicate Staff ID')
              # add the duplicate email message to the later row, if not there already
              records[iyall][COL_ERROR] = append_with_comma(records[iyall][COL_ERROR], 'Duplicate Staff ID') if !(records[iyall][COL_ERROR] ||= '').include?('Duplicate Staff ID')
            end
          end
        end
      end
      Rails.logger.debug("*** error_list: #{error_list.inspect}")
      # remove lines matching lines removed with -1 value
      error_list.delete_if{|_,v| v == '-1'}
      Rails.logger.debug("*** cleaned error_list: #{error_list.inspect}")
      return {records: records, error_list: error_list, abort: false}
    rescue StandardError => e
      return {records: records, error_list: error_list, abort: true}
    end
  end


  # student bulk upload file stage 4 and 5 processing
  def build_staff(csv_hash)
    begin
      new_staff = User.new
      new_staff.school_id = @school.id
      new_staff.first_name = csv_hash[COL_FNAME]
      new_staff.last_name = csv_hash[COL_LNAME]
      new_staff.email = csv_hash[COL_EMAIL]
      posit = csv_hash[COL_POSIT]
      posit ||= ' - '
      case posit.split('-')[0].upcase
      when 'T'
        set_role(new_staff, 'teacher', true)
      when 'A'
        set_role(new_staff, 'school_administrator', true)
      when 'C'
        set_role(new_staff, 'counselor', true)
      else
        raise('Invalid Role')
      end
      # new_staff.set_unique_username # Must be manually created (in transaction)
      new_staff.set_temporary_password
    rescue StandardError => e
      new_staff.errors.add(:base, " build_staff ERROR: #{e.inspect}")
    end
    return new_staff
  end

  # build unique username from staff fields and list of existing ones
  def build_unique_username(staff, school, usernames)
    # student.set_unique_username, remove special characters and replace spaces with .
    initial_username = (school.acronym + "_" + staff.first_name[0] + staff.last_name).downcase.gsub(/[^0-9a-z -_\.]+/, '').gsub(/ /, '.')
    work_username = initial_username
    incr = 2
    until usernames[work_username] == nil
      work_username = initial_username+(incr.to_s)
      incr += 1
    end
    return work_username
  end


end
