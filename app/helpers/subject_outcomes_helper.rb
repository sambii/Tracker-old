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
  MATCH_LEVEL_OPTIONS = [['loosest', 1], ['looser', 2], ['loose', 3], ['tight', 4], ['tighter', 5], ['tightest', 6]]

  DEFAULT_MATCH_LEVEL = 6
  MAX_MATCH_LEVEL = 6

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
    # match_h[:course_match] = 0
    # match_h[:grade_match] = 0
    # match_h[:mp_match] = 0
    match_h[:code_match] = 0
    match_h[:desc_match] = 0
    # match_h[:active_match] = 0
    match_h[:total_match] = 0
    # note setting default PARAM_ACTION sets the length of the old and new recs to be at least 1
    # Rails.logger.debug("*** passed matching check")
    white = Text::WhiteSimilarity.new
    # match_h[:course_match] = 1 if old_rec[:course] == new_rec[COL_COURSE]
    # match_h[:grade_match] = 1 if old_rec[:grade] == new_rec[COL_GRADE]
    # match_h[:mp_match] = 1 if old_rec[:mp] == new_rec[COL_MP_BITMAP]
    code_old = (old_rec[DB_OUTCOME_CODE].present?) ? old_rec[DB_OUTCOME_CODE].strip().split.join('\n') : ''
    code_new = (new_rec[COL_OUTCOME_CODE].present?) ? new_rec[COL_OUTCOME_CODE].strip().split.join('\n') : ''
    match_h[:code_match] = ( code_old == code_new ) ? 2 : (white.similarity(code_old, code_new) * 1.99).floor
    # match_h[:code_match] = ( old_rec[DB_OUTCOME_CODE] == new_rec[COL_OUTCOME_CODE] ) ? 3 : (white.similarity(old_rec[DB_OUTCOME_CODE], new_rec[COL_OUTCOME_CODE]) * 2.99).floor
    desc_old = (old_rec[:desc].present?) ? old_rec[:desc].strip().split.join('\n') : ''
    desc_new = (new_rec[COL_OUTCOME_NAME].present?) ? new_rec[COL_OUTCOME_NAME].strip().split.join('\n') : ''
    match_h[:desc_match] = ( desc_old == desc_new ) ? 4 : (white.similarity(desc_old, desc_new) * 3.99).floor
    # match_h[:active_match] = old_rec[:active] == true ? 1 : 0
    match_h[:total_match] = match_h.inject(0) {|total, (k,v)| total + v} # sum of all values in match_h
    return match_h
  end

  def lo_match_old(old_rec, new_recs, match_level)
    return_array = []
    # check matching against all new records, returning all that match at or above match_level
    new_recs.each do |new_rec|
      match_h = get_matching_level(old_rec, new_rec)
      return_array << [old_rec, new_rec, match_h] if ( match_level <= match_h[:total_match] )
    end
    # return_array.each do |a|
    #   old_rec_to_match = a[0]
    #   matched_new_rec = a[1]
    #   matched_weights = a[2]
    #   if old_rec_to_match[:active] == true
    #     # active old record
    #     if matched_new_rec[:rec_id].present?
    #       matched_new_rec[:action] = :'='
    #       # @do_nothing_count += 1
    #     else
    #       matched_new_rec[:action] = :'-'
    #       # @deactivate_count += 1
    #     end
    #   else
    #     # inactive old record
    #     if matched_new_rec[:rec_id].present?
    #       # reactivate it
    #       matched_new_rec[:action] = :'+'
    #       # @reactivate_count += 1
    #     else
    #       matched_new_rec[:action] = :'='
    #       # @do_nothing_count += 1
    #     end
    #   end
    # end
    # if no matches add a pair with a blank new record (for deactivation)
    if return_array.length == 0
      match_h = get_matching_level(old_rec, {})
      return_array << [old_rec, {action: :'-'}, match_h]
    end
    # return matches in descending match_level order
    sorted_array = return_array.sort_by { |pair| pair[2][:match_level_total] }.reverse!
    return sorted_array
  end

  def lo_add_new(new_rec)
    return_array = []
    new_rec_clone = new_rec.clone
    new_rec_clone[:action] = :'+'
    new_rec_clone[:unique] = true
    new_rec_clone[:matched] = '-1'
    match_h = get_matching_level({}, new_rec_clone)
    return_array << [{}, new_rec_clone, match_h]
  end

  def lo_get_model_school(params)
    # get school from school_id parameter if there
    @school = (params['school_id'].present?) ? School.find(params['school_id']) : nil
    # make sure school is model school, else look up the model school
    if @school.blank? || @school.acronym != 'MOD'
      match_model_schools = School.where(acronym: 'MOD')
      if match_model_schools.count == 1
        @school = match_model_schools.first
      else
        @errors[:school] = 'ERROR: Missing Model School'
        raise @errors[:school]
      end
    end
    if @school.school_year_id.blank?
      @errors[:school] = 'ERROR: Missing school year for Model School'
      raise @errors[:school]
    else
      @school_year = @school.school_year
      session[:school_context] = @school.id
      set_current_school
    end
    if !@school.has_flag?(School::GRADE_IN_SUBJECT_NAME)
      @errors[:school] = 'Error: Bulk Upload LO is for schools with grade in subject name only.'
      raise @errors[:school]
    end
    return @school
  end

  def lo_get_match_subject(params)
    # if only processing one subject, look up the subject by selected subject ID
    @match_subject = nil
    @subject_id = ''
    if params[:subject_id].present?
      match_subjects = Subject.where(id: params[:subject_id])
      if match_subjects.count == 0
        @errors[:subject] = "Error: Cannot find subject"
        raise @errors[:subject]
      else
        @match_subject = match_subjects.first
        @subject_id = @match_subject.present? ? @match_subject.id : ''
      end
    end
    Rails.logger.debug("*** @match_subject: #{@match_subject} = #{@match_subject.name.unpack('U' * @match_subject.name.length)}") if @match_subject
  end

  def lo_get_file_from_hidden(params)
    # recreate uploaded records to process
    new_los_by_rec = Hash.new
    params['pair'].each do |p|
      pold = p[1]['o']
      pold ||= {}
      pnew = p[1]['n']
      pnew ||= {}
      # recreate upload records (with only fields needed)
      if pnew.length > 0 && pnew[COL_REC_ID] && pnew[COL_OUTCOME_CODE]
        rec  = Hash.new
        rec[COL_REC_ID] = pnew[COL_REC_ID]
        rec[COL_COURSE] = pnew[COL_COURSE]
        rec[COL_COURSE_ID] = pnew[COL_COURSE_ID]
        rec[COL_GRADE] = pnew[COL_GRADE]
        rec[COL_MP_BITMAP] = pnew[COL_MP_BITMAP]
        rec[COL_OUTCOME_CODE] = pnew[COL_OUTCOME_CODE]
        rec[COL_OUTCOME_NAME] = pnew[COL_OUTCOME_NAME]
        rec[PARAM_ID] = pnew[PARAM_ID]
        rec[PARAM_ACTION] =  pnew[PARAM_ACTION]
        @records << rec
        new_los_by_rec[pnew[COL_REC_ID]] = rec
      end
    end
    return new_los_by_rec
  end

  def lo_get_file_from_upload(params)
    # no initial errors, process file
    @filename = params['file'].original_filename
    # @errors[:filename] = 'Choose file again to rerun'
    # note: 'headers: true' uses column header as the key for the name (and hash key)
    new_los_by_rec = Hash.new
    ix = 0 # record number (ignore other subject records if matching subject)
    CSV.foreach(params['file'].path, headers: true) do |row|
      rhash = validate_csv_fields(row.to_hash.with_indifferent_access, @subject_names)
      rhash[COL_REC_ID] = ix
      if rhash[COL_ERROR]
        @errors[:base] = 'Errors exist - see below:' if !rhash[COL_EMPTY]
      end
      # check if course and grade match an existing subject name
      check_subject = rhash[COL_SUBJECT]
      if @match_subject.blank?
        ix += 1
        matched_subject = false
        # processing all subjects in file
        Rails.logger.debug("*** Add @records item: #{rhash.inspect}")
        Rails.logger.debug("*** match (any) subject: #{matched_subject} for #{check_subject} = #{check_subject.unpack('U' * check_subject.length)}")
        @records << rhash if !rhash[COL_EMPTY]
        new_los_by_rec[pnew[COL_REC_ID]] = rhash
      else
        matched_subject = (@match_subject.name == check_subject)
        if matched_subject
          ix += 1
          Rails.logger.debug("*** Add @records item: #{rhash.inspect}")
          Rails.logger.debug("*** match subject: #{matched_subject} for #{check_subject} = #{check_subject.unpack('U' * check_subject.length)}")
          @records << rhash if !rhash[COL_EMPTY]
          new_los_by_rec[pnew[COL_REC_ID]] = rhash
        end
      end
    end  # end CSV.foreach
    return new_los_by_rec
  end

  def lo_get_old_los
    # get the subject outcomes from the database for all subjects to process
    old_los_by_lo = Hash.new
    # optimize active record for one db call
    SubjectOutcome.where(subject_id: @subject_ids.map{|k,v| k}).each do |so|
      subject_name = @subject_ids[so.subject_id].name
      # only add record if all subjects or the matching selected subject
      if @match_subject.blank? || @match_subject.name == subject_name
        Rails.logger.debug("*** Subject Outcome: #{so.inspect}")
        old_los_by_lo[so.lo_code] = {
          db_id: so.id,
          subject_name: subject_name,
          subject_id: so.subject_id,
          lo_code: so.lo_code,
          name: so.name,
          short_desc: so.shortened_description,
          desc: so.description,
          course: so.subject.subject_name_without_grade,
          grade: so.subject.grade_from_subject_name,
          mp: SubjectOutcome.get_bitmask_string(so.marking_period),
          active: so.active
        }
      end
    end
    return old_los_by_lo
  end

  def lo_set_selections_as_matched
    # get the selections from params
    # set :matched flag for selected pairs (from radio button selection)
    # detect when new record is assigned to multiple old records.
    pairs_matched = []
    selection_params = params['selections'].present? ? params['selections'] : {}
    selection_params.each do |old_lo_code, new_rec_id|
      val_new_new_rec_id = Integer(new_rec_id) rescue -1
      Rails.logger.debug("*** old_lo_code: #{old_lo_code}, new_rec_id: #{new_rec_id}")
      if val_new_new_rec_id < 0 || old_lo_code == new_rec_id
        # resetting this assignment - ignore it
      elsif @new_los_by_rec[new_rec_id][:matched].present?
        #
        @new_los_by_rec[new_rec_id][:error] = true
        @old_los_by_lo[old_lo_code][:error] = true
        @old_los_by_lo[old_lo_code][:matched] = nil
      else
        @old_los_by_lo[old_lo_code][:matched] = new_rec_id
        @new_los_by_rec[new_rec_id][:matched] = old_lo_code
        pairs_matched << [old_rec, new_rec, get_matching_level(old_rec, new_rec)]
      end
    end
    return pairs_matched
  end

end
