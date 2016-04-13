# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
module SubjectOutcomesHelper

  include ApplicationHelper

  # staff file column labels
  COL_REC_ID = :'rec_id'
  COL_COURSE = :'Course'
  COL_GRADE = :'Grade'
  COL_SUBJECT = :'Subject'
  COL_SEMESTER = :'Semester'
  COL_MARK_PER = :'Marking Period'
  COL_MP_BITMAP = :'mp_bitmap'
  COL_OUTCOME_CODE = :'LO Code:'
  DB_OUTCOME_CODE = :'lo_code'
  COL_OUTCOME_NAME = :'Learning Outcome'
  COL_SHORTENED_NAME = :'Short Description'
  COL_ERROR = :'error'
  COL_SUCCESS = :'success'
  COL_EMPTY = :'empty'
  COL_COURSE_ID = :'course_id'
  COL_DB_ID = :'db_id'
  COL_ACTIVE = :'active'
  COL_STATE = :'state'
  PARAM_ID = :'id'
  PARAM_ACTION = :'action'

  # matching levels
  MATCH_LEVEL_OPTIONS = [['loosest', 1], ['looser', 2], ['more loose', 3], ['loose', 4], ['tight', 5], ['more tight', 6], ['tighter', 7], ['tightest', 8]]

  # curriculum / LOs bulk upload file stage 2 processing - field validation
  def validate_csv_fields(csv_hash_in, subject_names)
    csv_hash = csv_hash_in.clone
    begin

      # ignore blank records
      if csv_hash[COL_COURSE].blank? && csv_hash[COL_GRADE].blank? && csv_hash[COL_SEMESTER].blank? && csv_hash[COL_MARK_PER].blank? && csv_hash[COL_OUTCOME_CODE].blank? && csv_hash[COL_OUTCOME_NAME].blank?
        # blank row, set indicator
        csv_hash[COL_EMPTY] = true
      #
      else
        # match synonymous fields (and set to primary field)

        # strip leading a trailing spaces in lo_code and name
        csv_hash[COL_OUTCOME_CODE] = csv_hash[COL_OUTCOME_CODE].strip
        csv_hash[COL_OUTCOME_NAME] = csv_hash[COL_OUTCOME_NAME].strip

        # make sure marking period is filled with either marking period field or semester field.
        if csv_hash[COL_MARK_PER].blank?
          if csv_hash[COL_SEMESTER].present?
            csv_hash[COL_MARK_PER] = csv_hash[COL_SEMESTER]
          end
        end

        # use the Subject Outcome coding to create the valid bit mask string from the marking period from the upload file
        bitmask = SubjectOutcome.get_bitmask(csv_hash[COL_MARK_PER])
        bitmask_str = SubjectOutcome.get_bitmask_string(bitmask)

        # convert 'Year Long' into the full year (based on the school marking periods) bit mask string
        all_mp_mask =@school.marking_periods.present? ? (2 ** @school.marking_periods)-1 : 0
        all_mp_mask_str = SubjectOutcome.get_bitmask_string(all_mp_mask)
        csv_hash[COL_MARK_PER] = all_mp_mask_str if csv_hash[COL_MARK_PER].strip.upcase == 'YEAR LONG'

        # preview the bitmap translation, and confirm nothing lost in round trip
        # csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], "Invalid Marking Period - #{bitmask_str} != #{csv_hash[COL_MARK_PER]} / #{csv_hash[COL_SEMESTER]}") if bitmask_str != csv_hash[COL_MARK_PER]

        # make sure marking period bitmask is valid marking period bitmask for school
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], "Marking Period too large") if bitmask > all_mp_mask

        # copy validated marking period into bitmap
        csv_hash[COL_MP_BITMAP] = csv_hash[COL_MARK_PER]

        if csv_hash[COL_COURSE].blank?
          csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing Course / Subject')
        else
          if @school.has_flag?(School::GRADE_IN_SUBJECT_NAME)
            subj_grade = "#{csv_hash[COL_COURSE]} #{csv_hash[COL_GRADE]}"
            if subject_names[subj_grade].present?
              # Rails.logger.debug("+++ Matched Course and Grade for #{csv_hash[COL_COURSE]} #{csv_hash[COL_GRADE]}")
              csv_hash[COL_COURSE_ID] = subject_names[subj_grade][:id]
              csv_hash[COL_SUBJECT] = subj_grade
            else
              # check if semester in subject name
              # to do - allow matching of subject with marking periods when lo is for multiple marking periods !!
              # Rails.logger.debug("+++ No match on Course and Grade for #{csv_hash[COL_COURSE]} #{csv_hash[COL_GRADE]}")
              subj_grade_mp = "#{csv_hash[COL_COURSE]} #{csv_hash[COL_GRADE]}s#{bitmask_str}"
              if subject_names[subj_grade_mp].present?
                csv_hash[COL_COURSE_ID] = subject_names[subj_grade_mp][:id]
                csv_hash[COL_SUBJECT] = subj_grade_mp
              else
                csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], "Invalid Subject & Grade #{csv_hash[COL_SUBJECT]} - #{csv_hash[COL_COURSE]} #{csv_hash[COL_GRADE]}s#{csv_hash[COL_MP_BITMAP]}")
              end
            end
          else
            if subject_names[csv_hash[COL_COURSE]].blank?
              csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], "Invalid Subject #{csv_hash[COL_COURSE]}")
              csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], "#{csv_hash[COL_COURSE]}")
            else
              csv_hash[COL_COURSE_ID] = subject_names[csv_hash[COL_COURSE]][:id]
            end
          end
        end
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing Grade Level') if csv_hash[COL_GRADE].blank?
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing LO Code') if csv_hash[COL_OUTCOME_CODE].blank?
        csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], 'Missing Learning Outcome') if csv_hash[COL_OUTCOME_NAME].blank?
      #
      end
    rescue StandardError => e
      csv_hash[COL_ERROR] = append_with_comma(csv_hash[COL_ERROR], "Error validating csv fields: #{e.inspect}")
    end
    # only keep fields that we need for processing.
    csv_hash.slice!(COL_COURSE, COL_GRADE, COL_SEMESTER, COL_MARK_PER, COL_OUTCOME_CODE, COL_OUTCOME_NAME, COL_EMPTY, COL_ERROR, COL_COURSE_ID, COL_SUBJECT, COL_MP_BITMAP)
    return csv_hash
  end

  # curriculum / LOs bulk upload file stage 2 processing - duplicate LO Code check
  def validate_dup_lo_codes(records_in)
    records = records_in.clone
    begin
      error_list = Hash.new
      records.each_with_index do |rx, ix|
        # check all records following it for duplicated LO Code
        if !error_list[ix+2].present? || error_list[ix+2].present? && error_list[ix+2][0] != '-1'
          records.drop(ix+1).each_with_index do |ry, iy|
            iyall = iy + ix + 1 # index of the later row being tested
            # if later record has not been matched already, check if a match to current
            if rx[COL_OUTCOME_CODE] == ry[COL_OUTCOME_CODE] && rx[COL_SUBJECT] == ry[COL_SUBJECT]
              # Rails.logger.debug("*** Match of #{ix+2} and #{iyall+2} !!!")
              if !error_list[iyall+2].present? || (error_list[iyall+2].present? && error_list[iyall+2][0] != '-1')
                # put or add to end the list of duplicated lines, but only if not listed prior
                # ix+2 or iyall+2 for zero relative ruby arrays and ignoring the header line.
                if error_list[ix+2].present?
                  error_list[ix+2][1] += ", #{iyall+2}"
                else
                  error_list[ix+2] = [rx[COL_OUTCOME_CODE], "#{ix+2}, #{iyall+2}"]
                end
                error_list[iyall+2] = ['-1', '']
              end
              # add the duplicate LO Code message to this row, if not there already
              records[ix][COL_ERROR] = append_with_comma(records[ix][COL_ERROR], '*') if !(records[ix][COL_ERROR] ||= '').include?('*')
              # add the duplicate LO Code message to the later row, if not there already
              records[iyall][COL_ERROR] = append_with_comma(records[iyall][COL_ERROR], '*') if !(records[iyall][COL_ERROR] ||= '').include?('*')
            end
          end
        end
      end
      Rails.logger.debug("*** error_list: #{error_list.inspect}")
      # remove lines matching lines removed with -1 value
      error_list.delete_if{|_,v| v[0] == '-1'}
      return {records: records, error_list: error_list, abort: false}
    rescue StandardError => e
      return {records: records, error_list: error_list, abort: true}
    end
  end


  # curriculum / LOs bulk upload file stage 2 processing - duplicate LO Code check
  def validate_dup_lo_descs(records_in)
    records = records_in.clone
    begin
      error_list = Hash.new
      records.each_with_index do |rx, ix|
        # check all records following it for duplicated LO description
        if !error_list[ix+2].present? || error_list[ix+2].present? && error_list[ix+2][0] != '-1'
          records.drop(ix+1).each_with_index do |ry, iy|
            iyall = iy + ix + 1 # index of the later row being tested
            # if later record has not been matched already, check if a match to current
            if rx[COL_OUTCOME_NAME] == ry[COL_OUTCOME_NAME] && rx[COL_SUBJECT] == ry[COL_SUBJECT]
              # Rails.logger.debug("*** Match of #{ix+2} and #{iyall+2} !!!")
              if !error_list[iyall+2].present? || (error_list[iyall+2].present? && error_list[iyall+2][0] != '-1')
                # put or add to end the list of duplicated lines, but only if not listed prior
                # ix+2 or iyall+2 for zero relative ruby arrays and ignoring the header line.
                if error_list[ix+2].present?
                  error_list[ix+2][1] += ", #{iyall+2}"
                else
                  error_list[ix+2] = [rx[COL_OUTCOME_NAME], "#{ix+2}, #{iyall+2}"]
                end
                error_list[iyall+2] = ['-1', '']
              end
              # add the duplicate LO Description message to this row, if not there already
              records[ix][COL_ERROR] = append_with_comma(records[ix][COL_ERROR], '*') if !(records[ix][COL_ERROR] ||= '').include?('*')
              # add the duplicate LO Description message to the later row, if not there already
              records[iyall][COL_ERROR] = append_with_comma(records[iyall][COL_ERROR], '*') if !(records[iyall][COL_ERROR] ||= '').include?('*')
            end
          end
        end
      end
      Rails.logger.debug("*** error_list: #{error_list.inspect}")
      # remove lines matching lines removed with -1 value
      error_list.delete_if{|_,v| v[0] == '-1'}
      return {records: records, error_list: error_list, abort: false}
    rescue StandardError => e
      return {records: records, error_list: error_list, abort: true}
    end
  end

  def get_matching_level(old_rec, new_rec)
    match_h = Hash.new
    match_h[:course_match] = 0
    match_h[:grade_match] = 0
    match_h[:mp_match] = 0
    match_h[:code_match] = 0
    match_h[:desc_match] = 0
    match_h[:total_match] = 0
    # note setting default PARAM_ACTION sets the length of the old and new recs to be at least 1
    # Rails.logger.debug("*** passed matching check")
    white = Text::WhiteSimilarity.new
    match_h[:course_match] = 1 if old_rec[:course] == new_rec[COL_COURSE]
    match_h[:grade_match] = 1 if old_rec[:grade] == new_rec[COL_GRADE]
    match_h[:mp_match] = 1 if old_rec[:mp] == new_rec[COL_MP_BITMAP]
    code_old = (old_rec[DB_OUTCOME_CODE].present?) ? old_rec[DB_OUTCOME_CODE].strip().split.join('\n') : ''
    code_new = (new_rec[COL_OUTCOME_CODE].present?) ? new_rec[COL_OUTCOME_CODE].strip().split.join('\n') : ''
    match_h[:code_match] = ( code_old == code_new ) ? 3 : (white.similarity(code_old, code_new) * 2.99).floor
    # match_h[:code_match] = ( old_rec[DB_OUTCOME_CODE] == new_rec[COL_OUTCOME_CODE] ) ? 3 : (white.similarity(old_rec[DB_OUTCOME_CODE], new_rec[COL_OUTCOME_CODE]) * 2.99).floor
    desc_old = (old_rec[:desc].present?) ? old_rec[:desc].strip().split.join('\n') : ''
    desc_new = (new_rec[COL_OUTCOME_NAME].present?) ? new_rec[COL_OUTCOME_NAME].strip().split.join('\n') : ''
    match_h[:desc_match] = ( desc_old == desc_new ) ? 3 : (white.similarity(desc_old, desc_new) * 2.99).floor
    match_h[:total_match] = match_h.inject(0) {|total, (k,v)| total + v} # sum of all values in match_h
    return match_h
  end

  def lo_match_old(old_rec, new_lo_codes_h, new_lo_names_h, match_level)
    return_array = []
    single_return_array = []
    new_lo_codes_h.each do |code, new_rec|
      match_h = get_matching_level(old_rec, new_rec)
      return_array << [old_rec, new_rec, match_h] if ( match_level <= match_h[:total_match] )
    end
    new_lo_names_h.each do |desc, new_rec|
      match_h = get_matching_level(old_rec, new_rec)
      return_array << [old_rec, new_rec, match_h] if ( match_level <= match_h[:total_match] )
    end
    check_dups = return_array.sort_by { |pair| pair[1]['rec_id']}
    prior_rec_id = -1
    check_dups.each do |pair|
      Rails.logger.debug("*** check_dups: #{pair.inspect}")
      single_return_array << pair if pair[1]['rec_id'] != prior_rec_id
      prior_rec_id = pair[1]['rec_id']
    end
    if single_return_array.length == 0
      Rails.logger.debug("*** add remove pair ")
      # if no matches, then set to remove old record
      old_rec[PARAM_ACTION] = 'Remove'
      single_return_array << [old_rec, {}, match_h]
    end
    return single_return_array.sort_by { |pair| pair[2][:match_level_total] }.reverse!
  end

  def lo_add_new(new_rec)
    return_array = []
    match_h = get_matching_level({}, new_rec)
    return_array << [{}, new_rec, match_h]
  end


  # def lo_match_old_new(old_rec, new_match, match_level)
  #   # Rails.logger.debug("*** lo_match_old_new - old_rec: #{old_rec}, length: #{old_rec.length}")
  #   # Rails.logger.debug("*** lo_match_old_new - new_match: #{new_match}")
  #   return_array = []
  #   # match_h = Hash.new
  #   # match_h[:course_match] = 0
  #   # match_h[:grade_match] = 0
  #   # match_h[:mp_match] = 0
  #   # match_h[:code_match] = 0
  #   # match_h[:desc_match] = 0
  #   # match_h[:total_match] = 0
  #   match_h = get_matching_level(old_rec, new_match)
  #   old_rec[PARAM_ACTION] = ''
  #   new_match[PARAM_ACTION] = ''
  #   # note setting default PARAM_ACTION sets the length of the old and new recs to be at least 1
  #   if new_match.length > 1 && old_rec.length > 1
  #     # Rails.logger.debug("*** passed matching check")
  #     # white = Text::WhiteSimilarity.new
  #     # match_h[:course_match] = 1 if old_rec[:course] == new_match[COL_COURSE]
  #     # match_h[:grade_match] = 1 if old_rec[:grade] == new_match[COL_GRADE]
  #     # match_h[:mp_match] = 1 if old_rec[:mp] == new_match[COL_MP_BITMAP]
  #     # match_h[:code_match] = ( old_rec[DB_OUTCOME_CODE] == new_match[COL_OUTCOME_CODE] ) ? 3 : (white.similarity(old_rec[DB_OUTCOME_CODE], new_match[COL_OUTCOME_CODE]) * 2.99).floor
  #     # desc_old = old_rec[:desc].strip().split.join('\n') # remove carriage returns and leading/trailing spaces
  #     # desc_new = new_match[COL_OUTCOME_NAME].strip().split.join('\n') # remove carriage returns and leading/trailing spaces
  #     # match_h[:desc_match] = ( desc_old == desc_new ) ? 3 : (white.similarity(desc_old, desc_new) * 2.99).floor
  #     # match_h[:total_match] = match_h.inject(0) {|total, (k,v)| total + v} # sum of all values in match_h
  #     if match_h[:total_match] == 9
  #       # old and new are identitical, set to restore it if inactive
  #       if !old_rec[COL_ACTIVE]
  #         old_rec[PARAM_ACTION] = 'Restore'
  #       end
  #     end
  #   elsif old_rec.length > 1 && new_match.length == 1
  #     # old record with no matching new records - set to remove if active
  #     if old_rec[COL_ACTIVE] == TRUE
  #       old_rec[PARAM_ACTION] = 'Remove'
  #     end
  #   elsif new_match.length > 1
  #     # no old record to match new record - set to add
  #     new_match[PARAM_ACTION] = 'Add'
  #   end

  #   Rails.logger.debug("*** match_level: #{match_level} vs this match: #{match_h[:total_match]}")
  #   # return an array of matches, for more than one possible match
  #   return_array << [old_rec, new_match, match_h] if match_level <= match_h[:total_match]
  #   if return_array.length == 0
  #     # if no matches, then set to remove old record
  #     old_rec[PARAM_ACTION] = 'Remove'
  #     return_array << [old_rec, {}, match_h]
  #   end
  #   return return_array
  # end


end
