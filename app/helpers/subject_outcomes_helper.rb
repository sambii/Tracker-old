# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
module SubjectOutcomesHelper

  include ApplicationHelper

  # staff file column labels
  COL_REC_ID = :rec_id
  COL_COURSE = :'Course'
  COL_GRADE = :'Grade'
  COL_SUBJECT = :'Subject'
  COL_SEMESTER = :'Semester'
  COL_MARK_PER = :'Marking Period'
  COL_MP_BITMAP = :mp_bitmap
  COL_OUTCOME_CODE = :'LO Code:'
  DB_OUTCOME_CODE = :lo_code
  COL_OUTCOME_NAME = :'Learning Outcome'
  COL_SHORTENED_NAME = :'Short Description'
  COL_ERROR = :error
  COL_SUCCESS = :success
  COL_EMPTY = :empty
  COL_COURSE_ID = :subject_id
  COL_SUBJECT_ID = :subject_id
  COL_DB_ID = :db_id
  COL_ACTIVE = :active
  COL_STATE = :state
  PARAM_ID = :id
  PARAM_ACTION = :action

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
              csv_hash[COL_SUBJECT_ID] = subject_names[subj_grade][:id]
              csv_hash[COL_SUBJECT] = subj_grade
            else
              # check if semester in subject name
              # to do - allow matching of subject with marking periods when lo is for multiple marking periods !!
              # Rails.logger.debug("+++ No match on Course and Grade for #{csv_hash[COL_COURSE]} #{csv_hash[COL_GRADE]}")
              subj_grade_mp = "#{csv_hash[COL_COURSE]} #{csv_hash[COL_GRADE]}s#{bitmask_str}"
              if subject_names[subj_grade_mp].present?
                csv_hash[COL_SUBJECT_ID] = subject_names[subj_grade_mp][:id]
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
              csv_hash[COL_SUBJECT_ID] = subject_names[csv_hash[COL_COURSE]][:id]
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
    csv_hash.slice!(COL_COURSE, COL_GRADE, COL_SEMESTER, COL_MARK_PER, COL_OUTCOME_CODE, COL_OUTCOME_NAME, COL_EMPTY, COL_ERROR, COL_SUBJECT_ID, COL_SUBJECT, COL_MP_BITMAP)
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
    # match_h[:course] = old_rec[:course].present? ? old_rec[:course] : new_rec[COL_COURSE]
    # match_h[:grade] = old_rec[:grade].present? ? old_rec[:course] : new_rec[COL_GRADE]
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
    match_h[:lo_code] = code_new.present? ? code_new : code_old
    match_h[:subject_id] = new_rec[:subject_id].present? ? new_rec[:subject_id].to_i : old_rec[:subject_id]
    return match_h
  end

  def lo_match_old(old_rec, new_recs, match_level)
    return_array = []
    # check matching against all new records, returning all that match at or above match_level
    new_recs.each do |k, new_rec|
      match_h = get_matching_level(old_rec, new_rec)
      return_array << [old_rec, new_rec, match_h] if ( match_level <= match_h[:total_match] )
    end
    # if no matches add a pair with a blank new record (for deactivation)
    if return_array.length == 0
      match_h = get_matching_level(old_rec, {})
      return_array << [old_rec, {action: :'-'}, match_h]
    end
    # return matches in descending match_level order
    sorted_array = return_array.sort_by { |pair| pair[2][:match_level_total] }.reverse!
    return sorted_array
  end

  def lo_match_new(new_rec, old_recs, match_level)
    return_array = []
    # check matching against all new records, returning all that match at or above match_level
    old_recs.each do |k, old_rec|
      match_h = get_matching_level(old_rec, new_rec)
      return_array << [old_rec, new_rec, match_h] if ( match_level <= match_h[:total_match] )
    end
    # if no matches add a pair with a blank old record (for adding new)
    if return_array.length == 0
      match_h = get_matching_level({}, new_rec)
      return_array << [{action: :'+'}, new_rec, match_h]
    end
    # return matches in descending match_level order
    sorted_array = return_array.sort_by { |pair| pair[2][:match_level_total] }.reverse!
    # Rails.logger.debug("*** Pair for new_rec #{new_rec[:rec_id]}, sorted_array: #{sorted_array.inspect}")
    return sorted_array
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
    if params[SubjectOutcomesHelper::COL_SUBJECT_ID].present?
      match_subjects = Subject.where(id: params[SubjectOutcomesHelper::COL_SUBJECT_ID])
      if match_subjects.count == 0
        @errors[:subject] = "Error: Cannot find subject"
        raise @errors[:subject]
      else
        @match_subject = match_subjects.first
        @subject_id = @match_subject.present? ? @match_subject.id : ''
      end
    end
    # Rails.logger.debug("*** @match_subject: #{@match_subject} = #{@match_subject.name.unpack('U' * @match_subject.name.length)}") if @match_subject
    return @match_subject
  end

  def lo_get_processed_subject(params)
    # matching process required, determine which is the current subject to be processed as well as the nextprocessing one subject, look up the subject by selected subject ID
    @process_by_subject = nil
    @process_by_subject_next = nil
    @process_subject_id = params['process_subject_id']
    if params['process_subject_id'].present?
      process_subjects = Subject.where(id: params['process_subject_id'])
      if process_subjects.count == 0
        @errors[:subject] = "Error: Cannot find subject to process"
        raise @errors[:subject]
      else
        @process_by_subject = process_subjects.first
        @process_by_subject_id = @process_by_subject.present? ? @process_by_subject.id : ''
      end
    end
    return @process_by_subject
  end

  def lo_get_file_from_hidden(params)
    # recreate uploaded records to process
    new_los_by_rec = Hash.new
    new_los_by_lo_code = Hash.new
    records = Array.new
    params['r'].each do |p|
      seq = p[0]
      pnew = p[1]
      # Rails.logger.debug("*** pnew: #{pnew.inspect}")
      # recreate upload records (with only fields needed)
      if pnew.length > 0 && pnew[COL_REC_ID] && pnew[COL_OUTCOME_CODE]
        rec  = Hash.new
        rec[COL_REC_ID] = pnew[COL_REC_ID]
        rec[COL_COURSE] = pnew[COL_COURSE]
        rec[COL_SUBJECT_ID] = pnew[COL_SUBJECT_ID]
        rec[COL_GRADE] = pnew[COL_GRADE]
        rec[COL_MP_BITMAP] = pnew[COL_MP_BITMAP]
        rec[COL_OUTCOME_CODE] = pnew[COL_OUTCOME_CODE]
        rec[COL_OUTCOME_NAME] = pnew[COL_OUTCOME_NAME]
        rec[PARAM_ID] = pnew[PARAM_ID]
        rec[PARAM_ACTION] =  pnew[PARAM_ACTION]
        records << rec
        # Rails.logger.debug("*** Recreated record: #{rec.inspect}")
        new_los_by_rec[pnew[COL_REC_ID]] = rec
        new_los_by_lo_code[pnew[COL_OUTCOME_CODE]] = rec
      end
    end
    return {records: records, los_by_rec: new_los_by_rec, new_los_by_lo_code: new_los_by_lo_code}
  end

  def lo_get_file_from_upload(params)
    # no initial errors, process file
    new_los_by_rec = Hash.new
    new_los_by_lo_code = Hash.new
    records = Array.new
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
        # Rails.logger.debug("*** Add @records item: #{rhash.inspect}")
        # Rails.logger.debug("*** match (any) subject: #{matched_subject} for #{check_subject} = #{check_subject.unpack('U' * check_subject.length)}")
        records << rhash if !rhash[COL_EMPTY]
        new_los_by_rec[rhash[COL_REC_ID]] = rhash
        new_los_by_lo_code[rhash[COL_OUTCOME_CODE]] = rhash if !rhash[COL_EMPTY]
      else
        matched_subject = (@match_subject.name == check_subject)
        if matched_subject
          ix += 1
          # Rails.logger.debug("*** Add @records item: #{rhash.inspect}")
          # Rails.logger.debug("*** rhash[COL_EMPTY]: #{rhash[COL_EMPTY]}")
          # Rails.logger.debug("*** match subject: #{matched_subject} for #{check_subject} = #{check_subject.unpack('U' * check_subject.length)}")
          records << rhash if !rhash[COL_EMPTY]
          new_los_by_rec[rhash[COL_REC_ID]] = rhash if !rhash[COL_EMPTY]
          new_los_by_lo_code[rhash[COL_OUTCOME_CODE]] = rhash if !rhash[COL_EMPTY]
        end
      end
    end  # end CSV.foreach
    return {records: records, new_los_by_rec: new_los_by_rec, new_los_by_lo_code: new_los_by_lo_code}
  end

  def lo_get_old_los
    # get the subject outcomes from the database for all subjects to process
    old_los_by_lo = Hash.new
    # optimize active record for one db call
    # SubjectOutcome.where(subject_id: @subject_ids.map{|k,v| k}, active: true).each do |so|
    SubjectOutcome.where(subject_id: @subject_ids.map{|k,v| k}).each do |so|
      subject_name = @subject_ids[so.subject_id].name
      # only add record if all subjects or the matching selected subject
      # if @match_subject.blank? || @match_subject.name == subject_name
      if lo_subject_to_process?(so.subject_id)
        # Rails.logger.debug("*** Subject Outcome: #{so.inspect}")
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
    # set :matched to corresponding old/new IDs for selected pairs from radio button selection (or possibly exact matches)
    # detect when new record is assigned to multiple old records.
    pairs_matched = []

    selection_params = params['selections'].present? ? params['selections'] : {}
    Rails.logger.debug("*** selection_params: #{selection_params.inspect}")

    selection_params.each do |new_rec_id, old_lo_code|
      # val_new_new_rec_id = Integer(new_rec_id) rescue -1
      # Rails.logger.debug("*** lo_set_selections_as_matched new_rec_id: #{new_rec_id}, old_db_id: #{old_lo_code}")
      # Rails.logger.debug("*** @new_los_by_rec[new_rec_id]: #{@new_los_by_rec[new_rec_id].inspect}")
      new_rec = @new_los_by_rec[new_rec_id].present? ? @new_los_by_rec[new_rec_id] : Hash.new
      # Rails.logger.debug("*** @old_los_by_lo[old_lo_code]: #{@old_los_by_lo[old_lo_code].inspect}")
      old_rec = @old_los_by_lo[old_lo_code].present? ? @old_los_by_lo[old_lo_code] : Hash.new
      if new_rec[:matched].present?
        new_rec[:error] = true
        new_rec[:matched] = nil
      else
        new_rec[:matched] = old_lo_code
        pairs_matched << [old_rec, new_rec, get_matching_level(old_rec, new_rec)]
      end
    end
    Rails.logger.debug("*** pairs_matched: #{pairs_matched.inspect}")
    return pairs_matched
  end

  # def lo_get_matches_for_old
  #   # add matches to old records to @pairs_matched
  #   # find any matching new records for each old record (at @match_level)
  #   @old_los_by_lo.each do |rk, old_rec|
  #     # only match pairs for pairs not selected by user yet (in the @pairs_matched array)
  #     if old_rec[:matched].nil? || !old_rec[:error].present?
  #       # Rails.logger.debug("*** Matching: rk: #{rk}, old_rec: #{old_rec}")
  #       # matching_pairs = lo_match_old(old_rec, @records, @match_level)
  #       matching_pairs = lo_match_old(old_rec, @new_recs_to_process, @match_level)
  #       @pairs_matched.concat(matching_pairs)
  #     else
  #       # Rails.logger.debug("*** Already Matched: rk: #{rk}, old_rec: #{old_rec}")
  #       # # pair has already been selected, pass it forward
  #       # new_rec = @new_los_by_rec[old_rec[:matched]]
  #       # @pairs_matched << [old_rec, new_rec, get_matching_level(old_rec, new_rec)]
  #     end
  #   end
  # end

  def lo_get_matches_for_new
    # add matches to new records to @pairs_matched
    # find any matching database records for each new record (at @match_level)
    # @new_los_by_rec.each do |rk, new_rec|
    @new_recs_to_process.each do |rk, new_rec|
      # only match pairs for pairs not selected by user yet (in the @pairs_matched array) and no errors
      if new_rec[:matched].blank? || new_rec[:error].blank?
        Rails.logger.debug("*** Matching: rk: #{rk}, new_rec: #{new_rec.inspect}")
        matching_pairs = lo_match_new(new_rec, @old_los_by_lo, @match_level)
        @pairs_matched.concat(matching_pairs)
        # Rails.logger.debug("*** Matching: matching_pairs: #{matching_pairs}")
      else
        # Rails.logger.debug("*** Already Matched: rk: #{rk}, new_rec: #{new_rec.inspect}")
        # # pair has already been selected, pass it forward
        # new_rec = @new_los_by_rec[old_rec[:matched]]
        # @pairs_matched << [old_rec, new_rec, get_matching_level(old_rec, new_rec)]
      end
    end
  end

  def lo_process_pairs
    # Rails.logger.debug("*** @records.length: #{@records.length}")
    last_matched_new_rec_id = -999

    @pairs_matched.each_with_index do |pair, ix|
      matched_old_rec = pair[0].clone   # cloned to safely set action
      new_rec_to_match = pair[1].clone  # cloned to safely set unique flag
      matched_weights = pair[2]

    @pairs_filtered.each do |p|
      Rails.logger.debug("*** lo_process_pairs @pairs_filtered: #{pair[0][:lo_code]}, #{pair[1][COL_OUTCOME_CODE]}, #{pair[2][:lo_code]}, #{pair[2][:total_match]}")
    end
      # Rails.logger.debug("*** pair: #{[matched_old_rec, new_rec_to_match, matched_weights].inspect}")

      matched_db_id = matched_old_rec[:db_id]
      matched_rec_num = Integer(new_rec_to_match[:rec_id]) rescue -1
      # Rails.logger.debug("*** matched_db_id: #{matched_db_id}")
      # Rails.logger.debug("*** matched_rec_num: #{matched_rec_num}")

      old_lo_code = matched_old_rec[:lo_code]
      new_rec_to_match[:'matching_rec_id'] = new_rec_to_match[:rec_id]
      # Always set exact matches as :matched (for initial implementation & probably also for final implentation)
      if matched_weights[:total_match] == MAX_MATCH_LEVEL
        # Rails.logger.debug("*** matched")
        new_rec_to_match[:exact] = matched_old_rec[:db_id]
        matched_old_rec[:exact] = new_rec_to_match[:rec_id]
        @old_los_by_lo[old_lo_code][:exact] = new_rec_to_match[:rec_id] if matched_old_rec[:db_id].present?
      else
        # Rails.logger.debug("*** not matched")
        new_rec_to_match[:exact] = nil
        matched_old_rec[:exact] = nil
        @old_los_by_lo[old_lo_code][:exact] = nil if matched_old_rec[:db_id].present?
      end
      new_rec_to_match[:matched] = matched_old_rec[:db_id]
      matched_old_rec[:matched] = new_rec_to_match[:rec_id]
      @old_los_by_lo[old_lo_code][:matched] = matched_old_rec[:db_id] if matched_old_rec[:db_id].present?

      # Initial - no user matching process, based upon weight based matching.
      # Rails.logger.debug("matched_weights[:subject_id]: #{matched_weights[:subject_id]}")
      if lo_subject_to_process?(matched_weights[SubjectOutcomesController::COL_SUBJECT_ID])
        @process_count += 1 # if lo_subject_to_process?(matched_old_rec[SubjectOutcomesController::COL_SUBJECT_ID])
        if matched_old_rec[:active] == true
          # active old record
          # if matched_new_rec[:rec_id].present?
            if new_rec_to_match[:matched].present?
              new_rec_to_match[:action] = :'='
              matched_old_rec[:action] = :'='
              @do_nothing_count += 1 # if lo_subject_to_process?(matched_old_rec[SubjectOutcomesController::COL_SUBJECT_ID])
            else
              @error_count += 1 # if lo_subject_to_process?(matched_old_rec[SubjectOutcomesController::COL_SUBJECT_ID])
            end
        elsif matched_old_rec[:db_id].present?
          if new_rec_to_match[:matched].present?
            new_rec_to_match[:action] = :'^'
            matched_old_rec[:action] = :'^'
            @reactivate_count += 1 # if lo_subject_to_process?(matched_old_rec[SubjectOutcomesController::COL_SUBJECT_ID])
          else
            @error_count += 1 # if lo_subject_to_process?(matched_old_rec[SubjectOutcomesController::COL_SUBJECT_ID])
          end
        elsif matched_old_rec[:action] == :'+'
          # no matching old record, set new LO to add
          new_rec_to_match[:action] = :'+'
          matched_old_rec[:action] = :'+'
          @add_count += 1 # if lo_subject_to_process?(new_rec_to_match[SubjectOutcomesController::COL_SUBJECT_ID].to_i)
        else
          @error_count += 1 # if lo_subject_to_process?(matched_old_rec[SubjectOutcomesController::COL_SUBJECT_ID])
        end

        # Rails.logger.debug("*** pair: #{[matched_old_rec, new_rec_to_match, matched_weights].inspect}")
        # Rails.logger.debug("*** pair: #{matched_old_rec.lo_code}, #{new_rec_to_match[COL_OUTCOME_CODE]}, #{matched_weights[:total_match]}")
        @pairs_filtered << [matched_old_rec, new_rec_to_match, matched_weights]
        # Rails.logger.debug("*** filtered pair: #{[matched_old_rec, new_rec_to_match, matched_weights].inspect}")
      end

    end
  end

  # def lo_add_unmatched_new
  #   # Any unmatched new records are output as an 'Add' pair
  #   @records.each_with_index do |rx, ix|
  #     if rx[COL_STATE].blank? && rx[:action].blank? && lo_subject_to_process?(rx[SubjectOutcomesController::COL_SUBJECT_ID].to_i)
  #       @process_count += 1 # if lo_subject_to_process?(rx[SubjectOutcomesController::COL_SUBJECT_ID].to_i)
  #       @add_count += 1 # if lo_subject_to_process?(rx[SubjectOutcomesController::COL_SUBJECT_ID].to_i)
  #       # Rails.logger.debug("*** Add @record #{ix}: #{rx.inspect}")
  #       add_pair = []
  #       rx_clone = rx.clone
  #       rx_clone[:action] = :'+'
  #       rx_clone[:unique] = true
  #       rx_clone[:matched] = '-1'
  #       match_h = get_matching_level({}, rx_clone)
  #       add_pair << [{}, rx_clone, match_h]
  #       @pairs_filtered.concat(add_pair)
  #     end
  #   end
  # end

  def lo_deactivate_unmatched_old
    # Any unmatched old records are output as an 'deactivate' pair
    @old_los_by_lo.each do |rk, old_rec|
      # Rails.logger.debug("*** subject: #{old_rec[SubjectOutcomesController::COL_SUBJECT_ID].to_i}, process: #{ lo_subject_to_process?(old_rec[SubjectOutcomesController::COL_SUBJECT_ID].to_i)}")
      # Rails.logger.debug("*** Loop through old records: #{old_rec.inspect}")
      if old_rec[:active] == true && (old_rec[:matched].blank? || old_rec[:exact].blank?) && lo_subject_to_process?(old_rec[SubjectOutcomesController::COL_SUBJECT_ID].to_i)
        @process_count += 1 # if lo_subject_to_process?(old_rec[SubjectOutcomesController::COL_SUBJECT_ID].to_i)
        @deactivate_count += 1 # if lo_subject_to_process?(old_rec[SubjectOutcomesController::COL_SUBJECT_ID].to_i)
        # Rails.logger.debug("*** subject: #{old_rec[SubjectOutcomesController::COL_SUBJECT_ID].to_i}, process: #{ lo_subject_to_process?(old_rec[SubjectOutcomesController::COL_SUBJECT_ID].to_i)}")
        # Rails.logger.debug("*** Loop through old records: #{old_rec.inspect}")
        # Rails.logger.debug("*** Deactivate old_rec!!!!!!!") if lo_subject_to_process?(old_rec[SubjectOutcomesController::COL_SUBJECT_ID].to_i)
        add_pair = []
        old_rec_clone = old_rec.clone
        old_rec_clone[:action] = :'-'
        old_rec_clone[:matched] = '-1'
        new_rec = {subject_id: old_rec_clone[:subject_id], action: :'-'}
        match_h = get_matching_level(old_rec_clone, new_rec)
        matching_new_rec = @new_los_by_lo_code[match_h[:lo_code]]
        new_rec[:'matching_rec_id'] = matching_new_rec[:rec_id] if matching_new_rec.present?
        # old_rec_clone[:'rec_id'] = @new_los_by_lo_code[match_h[:lo_code]]
        # old_rec_clone[:lo_code] = match_h[:lo_code]
        add_pair << [old_rec_clone, new_rec, match_h]
        @pairs_filtered.concat(add_pair)
        Rails.logger.debug("*** Added pair: #{add_pair.inspect}")
      else
        # Rails.logger.debug("*** Skipped Adding pair for old_rec: #{old_rec.inspect}")
      end
    end
  end

  def lo_subject_to_process?(subject_id)
    if @match_subject
      # Rails.logger.debug("***  lo_subject_to_process? @match_subject.id: #{@match_subject.id}, return: #{@match_subject.id == subject_id}")
      return @match_subject.id == subject_id
    else
      if @process_by_subject
        # Rails.logger.debug("*** lo_subject_to_process? @process_by_subject.id: #{@process_by_subject.id},  @process_by_subject_id: #{@process_by_subject_id}, return: #{@process_by_subject_id == subject_id}")
        return @process_by_subject_id == subject_id
      else
        # Rails.logger.debug("*** lo_subject_to_process? return: always true")
        return true
      end
    end
  end

  def lo_get_new_recs_to_process(recs)
    # Rails.logger.debug("@match_subject: #{@match_subject.inspect}")
    # Rails.logger.debug("@process_by_subject: #{@process_by_subject.inspect}")
    # Rails.logger.debug("@process_by_subject_id: #{@process_by_subject_id.inspect}")
    return_recs = Hash.new
    recs.each do |r|
      # Rails.logger.debug("r[COL_SUBJECT_ID]: #{r[COL_SUBJECT_ID]} - include rec: #{lo_subject_to_process?((Integer(r[COL_SUBJECT_ID]) rescue -1))}")
      return_recs[r[COL_REC_ID]] = r if lo_subject_to_process?((Integer(r[COL_SUBJECT_ID]) rescue -1))
    end
    # Rails.logger.debug("new return_recs: #{return_recs.inspect}")
    return return_recs
  end

  # def lo_get_old_recs_to_process(recs)
  #   Rails.logger.debug("lo_get_old_recs_to_process")
  #   return_recs = Hash.new
  #   recs.each do |h, r|
  #     Rails.logger.debug("r: #{r.inspect}")
  #     Rails.logger.debug("subject_id: #{r[:subject_id].inspect}")
  #     # return_recs[r[:lo_code]] = r if lo_subject_to_process?(r[:subject_id])
  #   end
  #   Rails.logger.debug("old return_recs: #{return_recs.inspect}")
  #   return return_recs
  # end

  def check_matching_counts
    Rails.logger.debug("*** @pairs_matched.count: #{@pairs_matched.count}")

    # need to turn on is_matched logic in lo_matching.html.haml
    # need to turn on radio buttons
    # when is :matched set on new records (see lo_matching.html.haml, subject_outcome_helper.rb/lo_set_selections_as_matched)
    # matching on @old_los_by_lo gets matched groupings for display to user.  Note these need to be grouped by the UI.  Note these need to be presented to user for selection by radio buttons.
    # How are items matched in lo_set_selections_as_matched determined to not have radio buttons in UI

    Rails.logger.debug("*** @mismatch_count: #{@mismatch_count}")
    Rails.logger.debug("*** submit_action: #{params[:submit_action]}")
    Rails.logger.debug("*** Update? : #{@mismatch_count == 0 && params[:submit_action] == 'save_all'}")

    Rails.logger.debug("*** database records count: #{@old_los_by_lo.count}")
    # Rails.logger.debug("*** old records to process count: #{@old_recs_to_process.count}")
    Rails.logger.debug("*** records count: #{@records.count}")
    Rails.logger.debug("*** new records to process count: #{@new_recs_to_process.count}")
    Rails.logger.debug("*** records_by_id count: #{@new_los_by_rec.length}")
    Rails.logger.debug("*** pairs_filtered count: #{@pairs_filtered.count}")
    Rails.logger.debug("*** mismatch_count : #{@mismatch_count}")
    Rails.logger.debug("*** not_add_count : #{@not_add_count}")
    Rails.logger.debug("*** add_count : #{@add_count}")
    Rails.logger.debug("*** do_nothing_count : #{@do_nothing_count}")
    Rails.logger.debug("*** reactivate_count : #{@reactivate_count}")
    Rails.logger.debug("*** deactivate_count : #{@deactivate_count}")
    Rails.logger.debug("*** @process_by_subject : #{@process_by_subject_id} - #{@process_by_subject.name}") if @process_by_subject.present?
    Rails.logger.debug("*** process_count : #{@process_count}")
    Rails.logger.debug("*** @do_nothing_count + @add_count : #{@do_nothing_count + @add_count}")
    Rails.logger.debug("*** @exact_match_count : #{@exact_match_count}")
    Rails.logger.debug("*** (@pairs_filtered.count - @exact_match_count) : #{(@pairs_filtered.count - @exact_match_count)}")
    Rails.logger.debug("*** (@new_recs_to_process.count - @exact_match_count) : #{(@new_recs_to_process.count - @exact_match_count)}")
    Rails.logger.debug("*** (@add_deact_count : #{@add_deact_count}")

    @allow_save = true
    @allow_save = false if @pairs_filtered.count != @do_nothing_count + @add_count
    @allow_save = false if @old_los_by_lo.count != @do_nothing_count
    @allow_save = false if @deactivate_count > 0
    @allow_save = false if @reactivate_count > 0
    Rails.logger.debug("*** allow_save : #{@allow_save}")


    @loosen_level = (@pairs_filtered.count - @exact_match_count) <= ((@new_recs_to_process.count - @exact_match_count) * 2)
    Rails.logger.debug("*** @loosen_level : #{@loosen_level}")

  end

  def clear_matching_counts
    @process_count = 0
    @mismatch_count = 0
    @add_count = 0
    @do_nothing_count = 0
    @reactivate_count = 0
    @deactivate_count = 0
    @error_count = 0
    @add_deact_count = 0
  end

  def lo_matching_at_level(first_run)
    step = 1
    clear_matching_counts
    @errors = Hash.new
    @records = @records_clean.clone
    # Rails.logger.debug("*** records ***")
    # @records.each do |p|
    #   Rails.logger.debug("*** record: #{p.inspect}")
    # end
    Rails.logger.debug("*** Step 1a")
    @new_recs_to_process = lo_get_new_recs_to_process(@records)
    # Rails.logger.debug("*** new_recs_to_process ***")
    # @new_recs_to_process.each do |p|
    #   Rails.logger.debug("*** new_recs_to_process: #{p.inspect}")
    # end
    @new_los_by_rec = @new_los_by_rec_clean.clone
    @new_los_by_lo_code = @new_los_by_lo_code_clean.clone
    # @new_los_by_rec.each do |rec|
    #   Rails.logger.debug("*** @new_los_by_rec: #{rec.inspect}")
    # end
    Rails.logger.debug("*** Step 1b")
    @pairs_filtered = Array.new
    @old_los_by_lo = lo_get_old_los
    @old_los_by_lo.each do |rec|
      Rails.logger.debug("*** @old_los_by_lo: #{rec.inspect}")
    end
    @old_records_counts = @old_los_by_lo.count
    step = 2
    Rails.logger.debug("*** Step #{step}")
    # @pairs_matched = first_run ? [] : lo_set_selections_as_matched
    # @pairs_matched.each do |rec|
    #   Rails.logger.debug("*** @pairs_matched: #{rec.inspect}")
    # end
    @pairs_matched = Array.new
    step = 3
    Rails.logger.debug("*** Step #{step}")
    lo_get_matches_for_new
    step = 4
    Rails.logger.debug("*** Step #{step}")
    lo_process_pairs
    @pairs_filtered.each do |p|
      Rails.logger.debug("*** lo_process_pairs pairs: #{p[0][:lo_code]}, #{p[1][COL_OUTCOME_CODE]}, #{p[2][:lo_code]}, #{p[2][:total_match]}")
    end
    step = 5
    Rails.logger.debug("*** Step #{step}")
    lo_deactivate_unmatched_old
    @pairs_filtered.sort_by! { |v| [v[2][:lo_code], -v[2][:total_match]]}
    @pairs_filtered.each do |p|
      Rails.logger.debug("*** sorted pairs: #{p[0][:lo_code]}, #{p[1][COL_OUTCOME_CODE]}, #{p[2][:lo_code]}, #{p[2][:total_match]}")
    end
    last_exact_match = ''
    last_matched = ''
    last_matched_recs = 0
    last_matched_adds = 0
    last_matched_deact = 0
    @exact_match_count = 0
    @pairs_filtered_n = Array.new
    # if there is an exact match
    # - remove all other options
    # Rails.logger.debug("*** Step #{step}")
    @pairs_filtered.each do |p|
      Rails.logger.debug("*** rec_id: #{p[1][COL_REC_ID]}, old code: #{p[0][:lo_code]}, new code: #{p[1][COL_OUTCOME_CODE]}, total match: #{p[2][:total_match]}, old[:matched]: #{p[0][:matched].inspect}, old[:exact]: #{p[0][:exact].inspect}")
      this_lo_code = p[2][:lo_code]
      this_is_exact = p[2][:total_match] == MAX_MATCH_LEVEL
      if this_is_exact
        last_exact_match = this_lo_code
        @exact_match_count += 1
      elsif last_exact_match != this_lo_code
        last_exact_match = ''
      end
      # Rails.logger.debug("*** this_lo_code: #{this_lo_code} ")
      # Rails.logger.debug("*** this_is_exact: #{this_is_exact} ")
      # Rails.logger.debug("*** last_exact_match: #{last_exact_match} ")
      # keep lo if no exact match for this lo_code, or is the exact match for this lo code
      # @pairs_filtered_n << p if last_exact_match != this_lo_code || (last_exact_match == this_lo_code && this_is_exact)
      if this_is_exact
        # output the exact match
        p[0][:matched] = p[1][:rec_id]
        Rails.logger.debug("*** exact match rec_id: #{p[0][:matched]} - #{p[1][:rec_id]} - #{p[1][:matching_rec_id]}")
        Rails.logger.debug("*** Pair: p[2] #{p[2].inspect}")
        Rails.logger.debug("*** Pair: code #{p[0][:lo_code]} <=> #{p[1][:'LO Code:']}")
        Rails.logger.debug("*** Pair: desc #{p[0][:desc]} <=> #{p[1][:'Learning Outcome']}")
        @pairs_filtered_n << p
        # don't # add the unmatch option
        # @pairs_filtered_n << [{action: 'x', matched: p[1][:rec_id]}, p[1], get_matching_level({}, p[1])]
        # @process_count += 1
        # Rails.logger.debug("*** lo_deactivate_unmatched_old - ADDED PAIR: #{[{action: 'x', matched_rec_id: p[1][:rec_id]}, p[1], get_matching_level({}, p[1])].inspect}")
      elsif last_exact_match != this_lo_code
        # output if not an exact match
        p[0][:matched] = p[1][:rec_id]
        Rails.logger.debug("*** not exact match rec_id: #{p[0][:matched]} - #{p[1][:rec_id]} - #{p[1][:matching_rec_id]}")
        Rails.logger.debug("*** Pair: p[2] #{p[2].inspect}")
        Rails.logger.debug("*** Pair: code #{p[0][:lo_code]} <=> #{p[1][:'LO Code:']}")
        Rails.logger.debug("*** Pair: desc #{p[0][:desc]} <=> #{p[1][:'Learning Outcome']}")
        @pairs_filtered_n << p
        # Rails.logger.debug("*** lo_deactivate_unmatched_old - NOT AN EXACT MATCH")
      else
        Rails.logger.debug("*** dropped after exact match rec_id: #{p[0][:matched]} - #{p[1][:rec_id]} - #{p[1][:matching_rec_id]}")
        # don't output the other pairs for the exact match
        # Rails.logger.debug("*** lo_deactivate_unmatched_old - DROP OTHERS ON EXACT MATCH")
      end
      # Rails.logger.debug("*** lo_deactivate_unmatched_old pairs: #{p[0].inspect}, #{p[1].inspect}, #{p[2].inspect}")
      # check
      if last_matched != p[0][:matched]
        # new record break
        if last_matched_recs > 1 && last_matched_deact > 0
          # need to tighten matching, because there is an add and deactivate on the same record
          @add_deact_count += 1
          last_matched = p[0][:matched]
          last_matched_recs = 0
          last_matched_adds = 0
          last_matched_deact = 0
        end
        last_matched_recs += 1
        case p[0][:action]
        when :'+'
          last_matched_adds += 1
        when :'-'
          last_matched_deact += 1
        end
      end

    end
    @pairs_filtered = @pairs_filtered_n
    step = 6
    check_matching_counts
  end

end
