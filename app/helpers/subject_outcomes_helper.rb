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

  MAX_CODE_LEVEL = 2
  MAX_DESC_LEVEL = 4
  MAX_MATCH_LEVEL = MAX_CODE_LEVEL + MAX_DESC_LEVEL
  DEFAULT_MATCH_LEVEL = MAX_MATCH_LEVEL - 1

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
    Rails.logger.debug("*** validate_dup_lo_codes")
    records = records_in.clone
    begin
      error_list = Hash.new
      records.each_with_index do |rx, ix|
        # check all records following it for duplicated LO Code
        if !error_list[ix+2].present? || error_list[ix+2].present? && error_list[ix+2][0] != '-1'
          # only process records after the current record
          records.drop(ix+1).each_with_index do |ry, iy|
            iyall = iy + ix + 1 # index of the later row being tested
            # if later record has not been matched already, check if a match to current
            if rx[COL_OUTCOME_CODE] == ry[COL_OUTCOME_CODE] && rx[COL_SUBJECT] == ry[COL_SUBJECT]
              Rails.logger.debug("*** Match of #{ix+2} and #{iyall+2} !!!")
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
              records[ix][COL_ERROR] = append_with_comma(records[ix][COL_ERROR], 'Dup LO Code') if !(records[ix][COL_ERROR] ||= '').include?('Dup LO Code')
              # add the duplicate LO Code message to the later row, if not there already
              records[iyall][COL_ERROR] = append_with_comma(records[iyall][COL_ERROR], 'Dup LO Code') if !(records[iyall][COL_ERROR] ||= '').include?('Dup LO Code')
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
              Rails.logger.debug("*** Match of #{ix+2} and #{iyall+2} !!!")
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
              records[ix][COL_ERROR] = append_with_comma(records[ix][COL_ERROR], 'Dup LO Desc') if !(records[ix][COL_ERROR] ||= '').include?('Dup LO Desc')
              # add the duplicate LO Description message to the later row, if not there already
              records[iyall][COL_ERROR] = append_with_comma(records[iyall][COL_ERROR], 'Dup LO Desc') if !(records[iyall][COL_ERROR] ||= '').include?('Dup LO Desc')
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
    match_h[:code_match] = 0
    match_h[:desc_match] = 0
    match_h[:total_match] = 0
    white = Text::WhiteSimilarity.new
    code_old = (old_rec[DB_OUTCOME_CODE].present?) ? old_rec[DB_OUTCOME_CODE].strip().split.join('\n') : ''
    code_new = (new_rec[:lo_code].present?) ? new_rec[:lo_code].strip().split.join('\n') : ''
    match_h[:code_match] = ( code_old == code_new ) ? MAX_CODE_LEVEL : (white.similarity(code_old, code_new) * (MAX_CODE_LEVEL - 0.01)).floor
    desc_old = (old_rec[:desc].present?) ? old_rec[:desc].strip().split.join('\n') : ''
    desc_new = (new_rec[:desc].present?) ? new_rec[:desc].strip().split.join('\n') : ''
    match_h[:desc_match] = ( desc_old == desc_new ) ? MAX_DESC_LEVEL : (white.similarity(desc_old, desc_new) * (MAX_DESC_LEVEL - 0.01)).floor
    match_h[:total_match] = match_h.inject(0) {|total, (k,v)| total + v} # sum of all values in match_h
    match_h[:lo_code] = code_new.present? ? code_new : code_old
    match_h[:subject_id] = new_rec[:subject_id].present? ? new_rec[:subject_id].to_i : old_rec[:subject_id]
    return match_h
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
    Rails.logger.debug("*** @match_subject: #{@match_subject.inspect} = #{@match_subject.name.unpack('U' * @match_subject.name.length)}") if @match_subject
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
        rec[:rec_id] = pnew[COL_REC_ID]
        rec[:subject_id] = pnew[COL_SUBJECT_ID]
        rec[:course] = pnew[COL_COURSE]
        rec[:grade] = pnew[COL_GRADE]
        rec[:mp] = pnew[COL_MP_BITMAP]
        # rec[:subject_name] = pnew[:subject_name]
        rec[:lo_code] = pnew[COL_OUTCOME_CODE]
        rec[:desc] = pnew[COL_OUTCOME_NAME]
        rec[:error] =  pnew[:error]
        # :exact_match=>{:key=>"BC", :descr=>"BC-MA.1.09", :val=>4, :db_id=>29, :rec_id=>28}
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

  def lo_get_all_old_los
    # create hash by subject containing array of all subject outcomes for each subject in this (model) school
    old_db_ids_by_subject = Hash.new()
    all_old_los = Hash.new()
    ix = 0
    subject_ids = @subject_ids.map{|k,v| k}
    # Rails.logger.debug("*** subject_ids: #{subject_ids.inspect}")
    SubjectOutcome.where(subject_id: subject_ids).includes(:subject).order('active DESC, lo_code, id').each do |so|
      old_rec = {
        match_id: ix.to_s(26).each_char.map {|i| ('A'..'Z').to_a[i.to_i(26)]}.join.to_s,
        db_id: so.id,
        subject_name: so.subject.name,
        subject_id: so.subject_id,
        lo_code: so.lo_code,
        desc: so.description,
        course: so.subject.subject_name_without_grade,
        grade: so.subject.grade_from_subject_name,
        mp: SubjectOutcome.get_bitmask_string(so.marking_period),
        active: so.active
      }
      # Rails.logger.debug("*** insert old rec: #{old_rec.inspect}")
      old_db_ids_by_subject[so.subject_id] = old_db_ids_by_subject[so.subject_id].present? ? old_db_ids_by_subject[so.subject_id] << old_rec[:db_id] : [old_rec[:db_id]]
      all_old_los[so.id] = old_rec
      ix += 1
      # Rails.logger.debug("*** old_db_ids_by_subject[#{so.subject_id}] #{old_db_ids_by_subject[so.subject_id]}")
    end

    return {old_db_ids_by_subject: old_db_ids_by_subject, all_old_los: all_old_los}
  end

  def lo_get_all_new_los(records)
    new_rec_ids_by_subject = Hash.new([])
    all_new_los = Hash.new
    records.each do |rec|
      Rails.logger.debug("*** lo_get_all_new_los rec: #{rec.inspect}")
      subject_id = Integer(rec[:subject_id]) rescue 0
      subject_name = @subject_ids[subject_id].name
      # fix for two different formats coming in:
      lo_code = rec[:lo_code].present? ? rec[:lo_code] : rec[:'LO Code:']
      lo_desc = rec[:desc].present? ? rec[:desc] : rec[:'Learning Outcome']
      lo_course = rec[:course].present? ? rec[:course] : rec[:'Course']
      lo_grade = rec[:grade].present? ? rec[:grade] : rec[:'Grade']
      lo_mp = rec[:mp].present? ? rec[:mp] : rec[:mp_bitmap]
      if subject_id > 0
        new_rec = {
          rec_id: rec[:rec_id],
          subject_name: subject_name,
          subject_id: subject_id,
          lo_code:  lo_code,
          desc: lo_desc,
          course: lo_course,
          grade: lo_grade,
          mp: lo_mp,
          error: rec[:error],
          exact_match: nil,
          matches: Hash.new
        }
        # Rails.logger.debug("*** insert new rec: #{new_rec.inspect}")
        new_rec_ids_by_subject[subject_id] = new_rec_ids_by_subject[subject_id].present? ? new_rec_ids_by_subject[subject_id] << new_rec[:rec_id] : [new_rec[:rec_id]]
        # Rails.logger.debug("*** new_rec_ids_by_subject[#{subject_id}]: #{new_rec_ids_by_subject[subject_id]}")
        all_new_los[new_rec[:rec_id]] = new_rec
        # Rails.logger.debug("*** all_new_los[#{new_rec[:rec_id]}]: #{all_new_los[new_rec[:rec_id]].inspect}")
      end
    end
    return {new_rec_ids_by_subject: new_rec_ids_by_subject, all_new_los: all_new_los}
  end

  # def lo_get_old_los_by_id(old_los)
  #   old_los_by_id = Hash.new
  #   old_los.each do |k,rec|
  #     old_los_by_id[rec[:db_id]] = rec
  #   end
  #   return old_los_by_id
  # end

  def lo_matches_for_subject(subj)
    step = 5
    Rails.logger.debug("*** Stage: #{@stage}, Subject #{subj.id}-#{subj.name} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
    exact_count = 0
    exact_deact_count = 0
    exact_active_count = 0
    dup_error_count = 0
    old_db_ids = @old_db_ids_by_subject[subj.id].present? ? @old_db_ids_by_subject[subj.id] : []
    new_rec_ids = @new_rec_ids_by_subject[subj.id].present? ? @new_rec_ids_by_subject[subj.id] : []
    Rails.logger.debug("*** old_db_ids: #{old_db_ids.inspect}")
    Rails.logger.debug("*** new_rec_ids: #{new_rec_ids.inspect}")
    # subj_flags = @subj_to_proc[subj.id].present? ? @subj_to_proc[subj.id] : {}
    subj_flags = {}
    new_rec_ids.each do |rec_id|
      new_rec = @all_new_los[rec_id]
      if new_rec[:error].present? # was an error in the duplicates checking
        dup_error_count += 1
        subj_flags[:error] = true
        subj_flags[:process] = true
      end
      desc_new = (new_rec[:desc].present?) ? new_rec[:desc].strip().split.join('\n') : ''
      old_db_ids.each do |db_id|
        old_rec = @all_old_los[db_id]
        desc_old = (old_rec[:desc].present?) ? old_rec[:desc].strip().split.join('\n') : ''
        if !new_rec[:error].blank?
          subj_flags[:error] = true
        end
        # if new_rec[:error].blank? && desc_new == desc_old
        if desc_new == desc_old
          exact_count += 1
          if old_rec[:active]
            exact_active_count += 1
          else
            exact_deact_count += 1
          end
          matching_h = {key: old_rec[:match_id], descr: "#{old_rec[:match_id]}-#{old_rec[:lo_code]}", val: MAX_DESC_LEVEL, db_id: old_rec[:db_id], rec_id: new_rec[:rec_id]}
          new_rec[:exact_match] = matching_h
          old_rec[:exact_match] = matching_h
          new_rec[:matches] = nil
          if new_rec[:lo_code] != old_rec[:lo_code]
            subj_flags[:code_change] = true
          end
          if !old_rec[:active]
            subj_flags[:reactivate] = true
          end
          if new_rec[:lo_code] != old_rec[:lo_code] || new_rec[:mp] != old_rec[:mp] || !old_rec[:active]
            subj_flags[:process] = true
          end
        end
      end
    end
    if exact_count == old_db_ids.count
      # no changes to old records
      if new_rec_ids.count > exact_count
        # all new records must be adds
        # subj_flags[:only_adds] = true
      elsif new_rec_ids.count == exact_count
        subj_flags[:skip] = true
      else
        # ? not possible
      end
    else
      subj_flags[:process] = true
    end
    db_deact_count = 0
    db_active_count = 0
    old_db_ids.each do |db_id|
      old_rec = @all_old_los[db_id]
      if old_rec[:active]
        db_active_count += 1
      else
        db_deact_count += 1
      end
    end
    # flag subject as add only if all new learning outcomes have exact matches in the database (active or deactivated)
    subj_flags[:add_only] = true if db_active_count == exact_active_count && db_deact_count >= exact_deact_count
    Rails.logger.debug("*** subj_flags[:add_only]: #{subj_flags[:add_only]}")
    Rails.logger.debug("*** #{db_active_count == exact_active_count} - db_active_count: #{db_active_count} ?=? exact_active_count: #{exact_active_count}")
    Rails.logger.debug("*** #{db_deact_count == exact_deact_count} - db_deact_count: #{db_deact_count} ?>=? exact_deact_count: #{exact_deact_count}")
    @subj_to_proc[subj.id] = subj_flags
    Rails.logger.debug("*** Subject: #{subj.id}-#{subj.name}, Old Count: #{old_db_ids.count}, New Count: #{new_rec_ids.count}, exact_count: #{exact_count}, @subj_to_proc[subj.id]: #{subj_flags.inspect}")
  end

  def lo_set_matches(new_recs_in, old_recs_in, old_db_ids_by_subject, all_old_los)
    step = 6
    Rails.logger.debug("*** Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
    # next set matching values for non exact matches
    new_recs_in.each do |new_rec|
      Rails.logger.debug("*** lo_set_matches new rec: #{new_rec.inspect}")
      subject_id = new_rec[:subject_id]
      rec_proc_count = 0
      if new_rec[:exact_match].blank?
        old_db_ids_by_subject[subject_id].each do |old_db_id|
          old_rec = all_old_los[old_db_id]
          rec_proc_count += 1
          if old_rec[:exact_match].blank?
            match_h = get_matching_level(old_rec, new_rec)
            matching_h = {key: old_rec[:match_id], descr: "#{old_rec[:match_id]}-#{old_rec[:lo_code]}", val: match_h[:desc_match], db_id: old_rec[:db_id], rec_id: new_rec[:rec_id]}
            # Rails.logger.debug("*** new rec: #{new_rec[:rec_id]}, old rec: #{old_rec[:db_id]}, match: #{match_h.inspect}")
            new_rec[:matches][old_rec[:match_id]] = matching_h
          end
        end
      end
      Rails.logger.debug("*** Stage: #{@stage}, subject_id #{subject_id}, recs: #{rec_proc_count} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
    end
    step = 7
    Rails.logger.debug("*** Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
    return
  end


  def lo_update_subject(subj)
    # update subject new records and deactivate extra old records
    new_rec_ids = @new_rec_ids_by_subject[subj.id].present? ? @new_rec_ids_by_subject[subj.id] : []
    subj_errors_count = 0
    new_rec_ids.each do |rec_id|
      new_rec = @all_new_los[rec_id]
      Rails.logger.debug("*** New rec to update: #{new_rec.inspect}")
      if new_rec[:exact_match].present?
        db_id = new_rec[:exact_match][:db_id]
        old_rec = @all_old_los[db_id]
        Rails.logger.debug("*** matching Old rec: #{db_id} - #{old_rec.inspect}")
        lo_update(new_rec, old_rec)
      else
        # should be none in :add_only mode
      end
    end
    # Deactivate all old records that are not :up_to_date
    if subj_errors_count == 0
      lo_deact_rest_old_recs(subj)
    end
    if subj_errors_count > 0
      @subj_to_proc[subj.id][:error] = true
    end
  end

  def lo_update(new_rec, old_rec)
    if new_rec[:error].blank?
      if new_rec[:lo_code] != old_rec[:lo_code] || new_rec[:desc] != old_rec[:desc] || new_rec[:mp] != old_rec[:mp] || !old_rec[:active]
        so = SubjectOutcome.find(old_rec[:db_id])
        so.active = true
        so.lo_code = new_rec[:lo_code]
        so.description = new_rec[:desc]
        so.marking_period = new_rec[:mp]
        so.save
        if so.errors.count > 0
          Rails.logger.error("*** Error updating : #{so.inspect}, #{so.errors.full_messages}")
          old_rec[:error] = so.errors.full_messages
          @count_errors += 1
        else
          old_rec[:up_to_date] = true
          Rails.logger.debug("*** Updated to : #{so.inspect}")
          @count_updates += 1
        end
      else
        old_rec[:up_to_date] = true
        Rails.logger.debug("*** already up to date : #{so.inspect}")
      end
    else
      old_rec[:error] = true
      Rails.logger.debug("*** error : #{so.inspect}")
    end
  end

  def lo_deact_rest_old_recs(subj)
    # Deactivate all old records that are not :up_to_date
    Rails.logger.debug("*** subj: #{subj} - #{subj.inspect}")
    old_db_ids = @old_db_ids_by_subject[subj.id].present? ? @old_db_ids_by_subject[subj.id] : []
    old_db_ids.each do |db_id|
      old_rec = @all_old_los[db_id]
      Rails.logger.debug("*** old_rec: #{db_id} - #{old_rec.inspect}")
      if (old_rec[:up_to_date].blank? || old_rec[:up_to_date] == false) && old_rec[:active] == true
        db_id = old_rec[:db_id]
        so = SubjectOutcome.find(db_id)
        Rails.logger.debug("*** Before Deactivation : #{so.inspect}")
        so.active = false
        so.save
        if so.errors.count > 0
          subj_errors_count += 1
          Rails.logger.error("*** Error updating : #{so.inspect}, #{so.errors.full_messages}")
          old_rec[:error] = so.errors.full_messages
          @count_errors += 1
        else
          old_rec[:up_to_date] = true
          Rails.logger.debug("*** Deactivated : #{so.inspect}")
          @count_deactivates += 1
        end
      end
    end
  end

  def lo_process_subject(subj)
    lo_matches_for_subject(subj)
    if @subj_to_proc[subj.id][:process] && !@subj_to_proc[subj.id][:add_only]
      Rails.logger.debug("*** DONT PROCESS ALL #{@subj_to_proc[subj.id]} - #{subj.inspect}")
      # This is a subject that must be matched, set up first presenting subject if not done already
      if @subject_to_show_next.blank?
        @subject_to_show_next = subj
      end
    elsif @subj_to_proc[subj.id][:process]
      # update this subject now and be done with it
      lo_update_subject(subj)
      # This is a subject that has errors, set up first presenting subject if not done already
      if @subj_to_proc[subj.id][:error].present? && @subject_to_show_next.blank
        @subject_to_show_next = subj
      end
    end
  end


  # def lo_get_matches_for_new
  #   # add matches to new records to @pairs_matched
  #   # find any matching database records for each new record (at @match_level)
  #   Rails.logger.debug("***")
  #   Rails.logger.debug("*** lo_get_matches_for_new")
  #   Rails.logger.debug("***")
  #   Rails.logger.debug("*** @selected_new_rec_ids: #{@selected_new_rec_ids.inspect}")
  #   Rails.logger.debug("*** @selections: #{@selections.inspect}")
  #   Rails.logger.debug("*** @selection_params: #{@selection_params.inspect}")
  #   @new_recs_to_process.each do |rk, new_rec|
  #     Rails.logger.debug("*** Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
  #     # Rails.logger.debug("*** new rec to process: #{new_rec.inspect}")
  #     new_rec_num = Integer(new_rec[:rec_id]) rescue -1
  #     new_lo_code = new_rec[:"LO Code:"]
  #     # only match pairs for pairs not selected by user yet (in the @pairs_matched array) and no errors
  #     if @selections[new_rec_num.to_s].present?
  #       db_id = Integer(@selections[new_rec_num.to_s]) rescue 0
  #       count = 0
  #       @selections.each { |k,v| count += 1 if v == db_id.to_s}
  #       Rails.logger.debug("*** matching db_id count: #{count}")
  #       if count > 1
  #         error_on_match = true
  #       else
  #         error_on_match = false
  #       end
  #       # Rails.logger.debug("*** Pre-selected: rk: #{rk}, new_rec: #{new_rec.inspect}")
  #       if @deactivations.include?(db_id.to_s)
  #         Rails.logger.debug("*** selection is also has a deactivation of the db record!")
  #         Rails.logger.debug("*** Error - do Matching: rk: #{rk}, new_rec: #{new_rec.inspect} at level: #{@match_level}")
  #         if @stage < 4 || @stage > 9
  #           # only do matching against old records with same lo_code (processing all subjects)
  #           matching_pairs = lo_match_new_for_rec(new_rec, @old_los_by_lo[new_rec[:'LO Code:']], @match_level)
  #         else
  #           matching_pairs = lo_match_new(new_rec, @old_los_by_lo, @match_level)
  #         end
  #         @pairs_matched.concat(matching_pairs)
  #         # Rails.logger.debug("*** Matching: matching_pairs: #{matching_pairs}")
  #       elsif db_id < 1
  #         # deselect chosen
  #         old_rec = @old_los_by_id[db_id*-1].present? ? @old_los_by_id[db_id*-1] : {}
  #         Rails.logger.debug("*** Deselect chosen - Generate pairs for old_rec: #{old_rec.inspect}")
  #         new_pair = [old_rec, new_rec, get_matching_level(old_rec, new_rec)]
  #         # Rails.logger.debug("*** new_pair: #{new_pair}")
  #         @pairs_matched << new_pair
  #       else
  #         # selection exists, generate a pair for it
  #         old_rec = @old_los_by_id[db_id].present? ? @old_los_by_id[db_id] : {}
  #         Rails.logger.debug("*** Generate pairs for old_rec: #{old_rec.inspect}")
  #         new_pair = [old_rec, new_rec, get_matching_level(old_rec, new_rec)]
  #         # Rails.logger.debug("*** new_pair: #{new_pair}")
  #         @pairs_matched << new_pair
  #       end
  #     # elsif new_rec[:matched].blank? || new_rec[:error].blank?
  #     else
  #       Rails.logger.debug("*** Matching: rk: #{rk}, new_rec: #{new_rec.inspect} at level: #{@match_level}")
  #       if @stage < 4 || @stage > 9
  #           # only do matching against old records with same lo_code (processing all subjects)
  #         matching_pairs = lo_match_new_for_rec(new_rec, @old_los_by_lo[new_rec[:'LO Code:']], @match_level)
  #       else
  #         matching_pairs = lo_match_new(new_rec, @old_los_by_lo, @match_level)
  #       end
  #       @pairs_matched.concat(matching_pairs)
  #       # Rails.logger.debug("*** Matching: matching_pairs: #{matching_pairs}")
  #     end
  #   end
  # end

  # def lo_process_pairs
  #   Rails.logger.debug("***")
  #   Rails.logger.debug("*** lo_process_pairs")
  #   Rails.logger.debug("***")
  #   last_matched_new_rec_id = -999

  #   Rails.logger.debug("*** @selections: #{@selections.inspect}")
  #   Rails.logger.debug("*** @selection_params: #{@selection_params.inspect}")

  #   @pairs_matched.each_with_index do |pair, ix|
  #     # Rails.logger.debug("*** pair: #{pair.inspect}")
  #     matched_old_rec = pair[0].clone   # cloned to safely set action
  #     new_rec_to_match = pair[1].clone  # cloned to safely set unique flag
  #     matched_weights = pair[2]

  #     # mark pair with unique id
  #     matched_weights[:pair_id] = ix

  #     matched_db_id = matched_old_rec[:db_id]
  #     matched_db_id_num = Integer(matched_old_rec[:db_id]) rescue -1
  #     matched_rec_num = Integer(new_rec_to_match[:rec_id]) rescue -1

  #     this_is_exact = matched_weights[:total_match] == MAX_MATCH_LEVEL
  #     this_desc_is_equal = matched_weights[:desc_match] == MAX_DESC_LEVEL
  #     if this_is_exact
  #       @exact_match_count += 1
  #       @update_as_equal_count += 1
  #       matched_weights[:status] = '1-Exact'
  #       matched_weights[:selected] = true
  #       @selected_count += 1
  #       @selected_pairs[matched_rec_num] = ix
  #       @selected_new_rec_ids << matched_rec_num
  #       Rails.logger.debug("*** exact match selection for - ix: #{ix} #{matched_weights.inspect}")
  #       # @old_los_by_lo[matched_old_rec[:lo_code]][:exact] = true if matched_old_rec[:db_id].present?
  #       @exact_db_ids << matched_old_rec[:db_id]  if matched_old_rec[:db_id].present?
  #     elsif this_desc_is_equal
  #       @update_as_equal_count += 1
  #       matched_weights[:status] = '2-Desc='
  #       @selected_count += 1
  #       @selected_pairs[matched_rec_num] = ix
  #       @selected_new_rec_ids << matched_rec_num
  #       Rails.logger.debug("*** description exact match selection for - ix: #{ix} #{matched_weights.inspect}")
  #     end


  #     if @selections.count > 0
  #       # mark selected pair
  #       Rails.logger.debug("*** Have Selections: #{matched_rec_num.to_s} -> #{@selections[matched_rec_num.to_s].inspect} ?=? #{matched_db_id_num.inspect}")
  #       if @selections[matched_rec_num.to_s] == matched_db_id_num.to_s
  #         # this pair's new rec num has a selection that points to this pair's database record.
  #         # this is the pair corresponding with the selection
  #         if @deactivations.include?(matched_db_id.to_s)
  #           Rails.logger.debug("*** selection is also has a deactivation of the db record!")
  #           matched_weights[:error] = 'also deactivated'
  #           matched_weights[:selected] = false
  #         elsif !this_is_exact
  #           matched_weights[:selected] = true
  #           @selected_count += 1
  #           count = 0
  #           @selections.each { |k,v| count += 1 if v == matched_db_id_num.to_s}
  #           Rails.logger.debug("*** matching db_id count: #{count}")
  #           if count > 1
  #             Rails.logger.debug("*** duplicated assignment to database record #{ix}")
  #             matched_weights[:error] = 'already assigned'
  #           else
  #             @selected_pairs[matched_rec_num] = ix
  #           end
  #           # todo fix this dup add to @selected_new_rec_ids
  #           # @selected_new_rec_ids << matched_rec_num
  #           Rails.logger.debug("*** matched selection for - ix: #{ix} #{matched_weights.inspect}")
  #         end
  #       end
  #     else
  #       Rails.logger.debug("*** Have No Selections - matched_rec_num: #{matched_rec_num}")
  #     end

  #     # save matching new record in old record (as well in pair)
  #     old_lo_code = matched_old_rec[:lo_code]
  #     new_rec_to_match[:matching_rec_id] = new_rec_to_match[:rec_id]
  #     if matched_weights[:selected] == true
  #       # Rails.logger.debug("*** set selected on old rec. matched_old_rec: #{matched_old_rec.inspect}")
  #       @old_los_by_lo[old_lo_code][:selected] = new_rec_to_match[:rec_id] if old_lo_code.present?
  #     # else
  #     #   @old_los_by_lo[old_lo_code][:matched] = nil if matched_old_rec[:db_id].present?
  #     end
  #     new_rec_to_match[:matched] = matched_old_rec[:db_id]
  #     matched_old_rec[:matched] = new_rec_to_match[:rec_id]
  #     @old_los_by_lo[old_lo_code][:matched] = matched_old_rec[:db_id] if matched_old_rec[:db_id].present?

  #     if lo_subject_to_process?(matched_weights[SubjectOutcomesController::COL_SUBJECT_ID])
  #       @process_count += 1
  #       if matched_old_rec[:active] == true
  #         # active old record
  #         if new_rec_to_match[:matched].present?
  #           if matched_weights[:total_match] == MAX_MATCH_LEVEL
  #             new_rec_to_match[:action] = :'=='
  #             matched_old_rec[:action] = :'=='
  #             matched_weights[:action] = :'=='
  #             matched_weights[:action_desc] = 'Exact Match'
  #             @do_nothing_count += 1
  #           else
  #             new_rec_to_match[:action] = :'~='
  #             matched_old_rec[:action] = :'~='
  #             matched_weights[:action] = :'~='
  #             matched_weights[:action_desc] = 'Close Match'
  #             @do_nothing_count += 1
  #           end
  #         else
  #           @error_count += 1
  #         end
  #       elsif matched_old_rec[:db_id].present?
  #         if new_rec_to_match[:matched].present?
  #           if matched_weights[:total_match] == MAX_MATCH_LEVEL
  #             new_rec_to_match[:action] = :'==^'
  #             matched_old_rec[:action] = :'==^'
  #             matched_weights[:action] = :'==^'
  #             matched_weights[:action_desc] = 'Exact Match Reactivate'
  #             @reactivate_count += 1
  #           else
  #             new_rec_to_match[:action] = :'~=^'
  #             matched_old_rec[:action] = :'~=^'
  #             matched_weights[:action] = :'~=^'
  #             matched_weights[:action_desc] = 'Close Match Reactivate'
  #             @reactivate_count += 1
  #           end
  #         else
  #           @error_count += 1
  #         end
  #       else
  #         # no matching old record, set new LO to add
  #         new_rec_to_match[:action] = :'+'
  #         matched_old_rec[:action] = :'+'
  #         matched_weights[:action] = :'+'
  #         matched_weights[:action_desc] = 'Add New'
  #         if @stage < 4 || @stage > 9
  #           # always select adds when processing all subjects
  #           matched_weights[:selected] = true
  #         end
  #         @add_count += 1
  #       end
  #       @pairs_filtered << [matched_old_rec, new_rec_to_match, matched_weights]
  #       # Rails.logger.debug("*** output pair: #{[matched_old_rec, new_rec_to_match, matched_weights]}")

  #     end # if subject to process

  #   end # pairs loop

  # end # lo_process_pairs

  def lo_deactivate_unmatched_old
    # Any unmatched old records are output as an 'deactivate' pair
    Rails.logger.debug("***")
    Rails.logger.debug("*** lo_deactivate_unmatched_old")
    Rails.logger.debug("***")
    Rails.logger.debug("*** @selected_pairs: #{@selected_pairs.inspect}")
    Rails.logger.debug("*** @selected_new_rec_ids: #{@selected_new_rec_ids.inspect}")
    Rails.logger.debug("*** @selected_db_ids: #{@selected_db_ids.inspect}")
    Rails.logger.debug("*** @deactivations: #{@deactivations.inspect}")

    @old_los_by_lo.each do |rk, old_rec|
      Rails.logger.debug("*** deactivate old record: old_rec: #{old_rec.inspect}")
      Rails.logger.debug("*** #{old_rec[:active]}, old_rec[:matched]: #{old_rec[:selected]}, old_rec[:selected]: #{old_rec[:selected]}, process? #{lo_subject_to_process?(old_rec[SubjectOutcomesController::COL_SUBJECT_ID].to_i)}")
      deactivate_me = false
      if @deactivations.include?(old_rec[:db_id].to_s)
        # user clicked deactivation radio button, so generate a deactivation pair
        deactivate_me = true
      end
      if old_rec[:active] == true && old_rec[:selected].blank? && old_rec[:matched].blank? && lo_subject_to_process?(old_rec[SubjectOutcomesController::COL_SUBJECT_ID].to_i)
      # if old_rec[:active] == true && old_rec[:status].blank? && lo_subject_to_process?(old_rec[SubjectOutcomesController::COL_SUBJECT_ID].to_i)
        # record has no new records assigned to it, so deactivate it
        deactivate_me = true
      end
      if deactivate_me
        @process_count += 1
        add_pair = []
        old_rec_clone = old_rec.clone
        old_rec_clone[:action] = :'-'
        old_rec_clone[:action_desc] = 'Remove (Inactivate)'
        old_rec_clone[:matched] = '-1'
        new_rec = {subject_id: old_rec_clone[:subject_id], action: :'-'}
        match_h = get_matching_level(old_rec_clone, new_rec)
        match_h[:action] = :'-'
        match_h[:action_desc] = 'Remove (Inactivate)'
        # Rails.logger.debug("*** match_h: #{match_h.inspect}")

        # set for radio button naming and for display groupings
        # using negative of db id here for easy identification of the database record to deactivate (no matching new record)
        matching_db_id = (Integer(old_rec_clone[:db_id]) rescue 999999) * -1
        new_rec[:matching_rec_id] = matching_db_id.to_s
        if @deactivations.include?(old_rec[:db_id].to_s)
          if @selected_db_ids.include?(old_rec[:db_id].to_s)
            # Rails.logger.debug("*** Deactivated record was also selected")
            match_h[:error] = 'also selected'
            match_h[:selected] = false
          else
            match_h[:selected] = true
          end
        else
          # Rails.logger.debug("*** Deactivated record not selected")
        end
        @deactivate_count += 1
        add_pair << [old_rec_clone, new_rec, match_h]
        @pairs_filtered.concat(add_pair)
        # Rails.logger.debug("*** Added deactivate pair: #{add_pair.inspect}")
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
    return_recs = Hash.new
    recs.each do |r|
      return_recs[r[COL_REC_ID]] = r if lo_subject_to_process?((Integer(r[COL_SUBJECT_ID]) rescue -1))
    end
    return return_recs
  end

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
    Rails.logger.debug("*** @old_los_by_lo.count: #{@old_los_by_lo.count}")
    # Rails.logger.debug("*** old records to process count: #{@old_recs_to_process.count}")
    Rails.logger.debug("*** @records count: #{@records.count}")
    Rails.logger.debug("*** @new_recs_to_process count: #{@new_recs_to_process.count}")
    Rails.logger.debug("*** @new_los_by_rec count: #{@new_los_by_rec.length}")
    Rails.logger.debug("*** @pairs_filtered count: #{@pairs_filtered.count}")
    Rails.logger.debug("*** @mismatch_count : #{@mismatch_count}")
    Rails.logger.debug("*** @not_add_count : #{@not_add_count}")
    Rails.logger.debug("*** @add_count : #{@add_count}")
    Rails.logger.debug("*** @do_nothing_count : #{@do_nothing_count}")
    Rails.logger.debug("*** @reactivate_count : #{@reactivate_count}")
    Rails.logger.debug("*** @deactivate_count : #{@deactivate_count}")
    Rails.logger.debug("*** @process_by_subject : #{@process_by_subject_id} - #{@process_by_subject.name}") if @process_by_subject.present?
    Rails.logger.debug("*** @process_count : #{@process_count}")
    Rails.logger.debug("*** @do_nothing_count + @add_count : #{@do_nothing_count + @add_count}")
    Rails.logger.debug("*** @exact_match_count : #{@exact_match_count}")
    Rails.logger.debug("*** (@pairs_filtered.count - @exact_match_count) : #{(@pairs_filtered.count - @exact_match_count)}")
    Rails.logger.debug("*** (@new_recs_to_process.count - @exact_match_count) : #{(@new_recs_to_process.count - @exact_match_count)}")
    Rails.logger.debug("*** @deactivations.count : #{@deactivations.count}")
    Rails.logger.debug("*** @selections.count : #{@selections.count}")
    Rails.logger.debug("*** @selection_params.count : #{@selection_params.count}")
    Rails.logger.debug("*** @error_count : #{@error_count}")
    Rails.logger.debug("*** @selected_count : #{@selected_count}")
    Rails.logger.debug("*** @unselect_count : #{@unselect_count}")
    Rails.logger.debug("*** @inactive_old_count : #{@inactive_old_count}")
    Rails.logger.debug("*** @stage : #{@stage}")
    Rails.logger.debug("*** @process_by_subject : #{@process_by_subject.present?}")
    Rails.logger.debug("*** @selected_pairs.count : #{@selected_pairs.count}")
    Rails.logger.debug("*** @selected_pairs.inspect : #{@selected_pairs.inspect}")

    @allow_save = true
    @allow_save_new = true
    # net_active = @deactivate_count + @inactive_old_count - @reactivate_count
    net_active = @deactivate_count - @reactivate_count
    Rails.logger.debug("*** net_active = #{net_active} = #{@deactivate_count} + #{@inactive_old_count} + #{@reactivate_count}}")
    # if !@process_by_subject && !@selection_params.present? && @pairs_filtered.count > 0
    if @stage < 4 || @stage > 9
      Rails.logger.debug("*** Test1 #{@records.count != @do_nothing_count + @add_count} = #{@records.count} != #{@do_nothing_count} + #{@add_count}")
      @allow_save = false if @records.count != @do_nothing_count + @add_count
      Rails.logger.debug("*** Test2 #{@old_los_by_lo.count != @do_nothing_count + net_active} = #{@old_los_by_lo.count} != #{@do_nothing_count} + #{net_active}")
      @allow_save = false if @old_los_by_lo.count != @do_nothing_count + net_active
      Rails.logger.debug("*** Test3 #{@deactivate_count > 0} = #{@deactivate_count} > 0")
      @allow_save = false if @deactivate_count > 0
      Rails.logger.debug("*** Test4 #{@reactivate_count > 0} = #{@reactivate_count} > 0")
      @allow_save = false if @reactivate_count > 0
      Rails.logger.debug("*** Test5 #{@error_count > 0} = #{@error_count} > 0")
      @allow_save = false if @error_count > 0
    else
      Rails.logger.debug("*** Test1 #{@selected_count != @new_recs_to_process.count || @error_count > 0} : #{@selected_count} != #{@new_recs_to_process.count} || #{@error_count > 0}")
      @allow_save = false if @selected_count != @new_recs_to_process.count || @error_count > 0
      Rails.logger.debug("*** Test2 #{@selected_count != @old_los_by_lo.count - @inactive_old_count + @add_count - net_active} : #{@selected_count} != #{@old_los_by_lo.count} - #{@inactive_old_count} + #{@add_count} - #{net_active}")
      @allow_save = false if @selected_count != @old_los_by_lo.count - @inactive_old_count + @add_count - net_active
      Rails.logger.debug("*** Test3 #{@new_recs_to_process.count != @pairs_filtered.count - @unselect_count - @deactivate_count} : #{@new_recs_to_process.count} != #{@pairs_filtered.count} - #{@deactivate_count} - #{@unselect_count}")
      @allow_save = false if @new_recs_to_process.count != @pairs_filtered.count - @unselect_count - @deactivate_count
      Rails.logger.debug("*** Test4 #{@pairs_filtered.count != @selected_count + @unselect_count + @deactivate_count} : #{@pairs_filtered.count} != #{@selected_count} + #{@unselect_count} + #{@deactivate_count}")
      @allow_save = false if @pairs_filtered.count != @selected_count + @unselect_count + @deactivate_count

      # make sure new records are not selected and added at the same time
      counts_h = Hash.new(0)
      sel_counts = @selection_params.map{ |k,v|counts_h[(Integer(k) rescue -99999).abs] += 1 }
      Rails.logger.debug("*** new records sel_counts: #{sel_counts.inspect}")
      Rails.logger.debug("*** Test5 #{sel_counts.length > 0 && sel_counts.max > 1}")
      @allow_save = false if sel_counts.length > 0 && sel_counts.max > 1
      @allow_save_new = false if sel_counts.length > 0 && sel_counts.max > 1

      # # make sure old records are not selected and deactivated at the same time
      # counts_h = Hash.new(0)
      # sel_counts = @selection_params.map{ |k,v|counts_h[(Integer(v) rescue -99999).abs] += 1 }
      # Rails.logger.debug("*** new records sel_counts: #{sel_counts.inspect}")
      # Rails.logger.debug("*** Test5 #{sel_counts.length > 0 && sel_counts.max > 1}")
      # @allow_save = false if sel_counts.length > 0 && sel_counts.max > 1
      # @allow_save_new = false if sel_counts.length > 0 && sel_counts.max > 1

      # new tests

      Rails.logger.debug("***")
      Rails.logger.debug("*** NEW TESTS")
      @allow_save_new = false if @error_count > 0
      Rails.logger.debug("*** New Test 1 #{@error_count > 0} : #{@error_count} > 0")

      Rails.logger.debug("*** @selection_params: #{@selection_params.inspect}")
      sel_matches = @selection_params.select{ |k,v| (Integer(k) rescue -1) > -1 && (Integer(v) rescue -1) > 0}
      Rails.logger.debug("*** sel_matches: (count: #{sel_matches.count})  #{sel_matches.inspect}")
      # sel_match_vals = sel_matches.map{ |k,v| Integer(v) rescue -99999}
      # Rails.logger.debug("*** sel_match_vals - max: #{sel_match_vals.max} - sum: #{sel_match_vals.sum}")
      sel_matches_counts_h = Hash.new(0)
      sel_matches_counts = sel_matches.map{ |k,v| sel_matches_counts_h[(Integer(k) rescue -99999).abs] += 1}
      Rails.logger.debug("*** sel_matches_counts: #{sel_matches_counts.inspect}")
      Rails.logger.debug("*** sel_matches_counts - count: #{sel_matches_counts.count} - max: #{(sel_matches_counts.max.present? ? sel_matches_counts.max : 0)} - sum: #{sel_matches_counts.sum}")

      @allow_save_new = false if (sel_matches_counts.max.present? ? sel_matches_counts.max : 0) > 1
      Rails.logger.debug("*** New Test 2 #{(sel_matches_counts.max.present? ? sel_matches_counts.max : 0) > 1} = #{(sel_matches_counts.max rescue 0)} > 1")
      @allow_save_new = false if @new_recs_to_process.count != sel_matches_counts.count
      Rails.logger.debug("*** New Test 3 #{@new_recs_to_process.count != sel_matches_counts.count} = #{@new_recs_to_process.count} != #{sel_matches_counts.count}")


      sel_deacts = @selection_params.select{ |k,v| (Integer(k) rescue -1) < 0}
      Rails.logger.debug("*** sel_deacts: #{sel_deacts.inspect}")
      Rails.logger.debug("*** sel_deacts: (count: #{sel_deacts.count})  #{sel_deacts.inspect}")
      # sel_deact_vals = sel_deacts.map{ |k,v| Integer(v) rescue -99999}
      # Rails.logger.debug("*** sel_deact_vals - max: #{sel_deact_vals.max} - sum: #{sel_deact_vals.sum}")
      sel_deacts_counts_h = Hash.new(0)
      sel_deacts_counts = sel_deacts.map{ |k,v| sel_deacts_counts_h[(Integer(k) rescue -99999).abs] += 1}
      Rails.logger.debug("*** sel_deacts_counts: #{sel_deacts_counts.inspect}")
      Rails.logger.debug("*** sel_deacts_counts - count: #{sel_deacts_counts.count} - max: #{sel_deacts_counts.max} - sum: #{sel_deacts_counts.sum}")

      sel_adds = @selection_params.select{ |k,v| (Integer(v) rescue -1) < 0}
      Rails.logger.debug("*** sel_adds: #{sel_adds.inspect}")
      Rails.logger.debug("*** sel_adds: (count: #{sel_adds.count})  #{sel_adds.inspect}")
      # sel_deact_vals = sel_adds.map{ |k,v| Integer(v) rescue -99999}
      # Rails.logger.debug("*** sel_deact_vals - max: #{sel_deact_vals.max} - sum: #{sel_deact_vals.sum}")
      sel_adds_counts_h = Hash.new(0)
      sel_adds_counts = sel_adds.map{ |k,v| sel_adds_counts_h[(Integer(k) rescue -99999).abs] += 1}
      Rails.logger.debug("*** sel_adds_counts: #{sel_adds_counts.inspect}")
      Rails.logger.debug("*** sel_adds_counts - count: #{sel_adds_counts.count} - max: #{sel_adds_counts.max} - sum: #{sel_adds_counts.sum}")

      Rails.logger.debug("*** New Test 4 #{@new_los_by_rec.count != @old_los_by_lo.count -  sel_deacts_counts.count + sel_adds_counts.count} = #{@new_los_by_rec.count} != #{@old_los_by_lo.count} - #{sel_deacts_counts.count} + #{sel_adds_counts.count}")
      @allow_save_new = false if @new_los_by_rec.count != @old_los_by_lo.count -  sel_deacts_counts.count + sel_adds_counts.count

      # counts_h = Hash.new(0)
      # sel_counts = @selections.map{ |k,v| counts_h[(Integer(k) rescue -99999).abs] += 1}
      # Rails.logger.debug("*** new records sel_counts: #{sel_counts.inspect}")
      # Rails.logger.debug("*** Test5 #{sel_counts.length > 0 && sel_counts.max > 1}")
      # @allow_save_new = false if sel_counts.length > 0 && sel_counts.max > 1
      # counts_h = Hash.new(0)
      # sel_counts = @selections.map{ |k,v| counts_h[(Integer(k) rescue -99999).abs] += 1}
      # Rails.logger.debug("*** db records sel_counts: #{sel_counts.inspect}")
      # Rails.logger.debug("*** Test-2 #{sel_counts.length > 0 && sel_counts.max > 1}")
      # @allow_save_new = false if sel_counts.length > 0 && sel_counts.max > 1


    end
    Rails.logger.debug("*** allow_save : #{@allow_save} (selections present?: #{@selection_params.present?})")
    Rails.logger.debug("*** allow_save_new : #{@allow_save_new} (selections present?: #{@selection_params.present?})")

    # @loosen_level = (@pairs_filtered.count - @exact_match_count) <= (([@new_recs_to_process.count, @old_los_by_lo.count].max - @exact_match_count) * 2)
    @loosen_level = (@pairs_filtered.count - @exact_match_count) <= ((@new_recs_to_process.count - @exact_match_count) * 2)
    Rails.logger.debug("*** @loosen_level = (#{@pairs_filtered.count} - #{@exact_match_count}) <= ((#{@new_recs_to_process.count - @exact_match_count}) * 2)")
    Rails.logger.debug("*** @loosen_level (#{@match_level}): #{@loosen_level}")

  end

  def clear_matching_counts
    @process_count = 0
    @mismatch_count = 0
    @add_count = 0
    @do_nothing_count = 0
    @reactivate_count = 0
    @deactivate_count = 0
    @selected_count = 0
    @unselect_count = 0
    @inactive_old_count = 0
    @exact_db_ids = Array.new
  end

  # def lo_matching_at_level(first_run)
  #   step = 1
  #   clear_matching_counts
  #   @records = @records_clean.clone
  #   # Rails.logger.debug("*** records ***")
  #   # @records.each do |p|
  #   #   Rails.logger.debug("*** record: #{p.inspect}")
  #   # end
  #   Rails.logger.debug("*** Step 1a Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
  #   @new_recs_to_process = lo_get_new_recs_to_process(@records)
  #   # Rails.logger.debug("*** new_recs_to_process ***")
  #   # @new_recs_to_process.each do |p|
  #   #   Rails.logger.debug("*** new_recs_to_process: #{p.inspect}")
  #   # end
  #   @new_los_by_rec = @new_los_by_rec_clean.clone
  #   @new_los_by_lo_code = @new_los_by_lo_code_clean.clone
  #   # @new_los_by_rec.each do |rec|
  #   #   Rails.logger.debug("*** @new_los_by_rec: #{rec.inspect}")
  #   # end
  #   Rails.logger.debug("*** Step 1b Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
  #   @pairs_filtered = Array.new
  #   @old_los_by_lo = lo_get_old_los
  #   # @old_los_by_lo.each do |rec|
  #   #   Rails.logger.debug("*** @old_los_by_lo: #{rec.inspect}")
  #   # end
  #   @old_los_by_id = lo_get_old_los_by_id(@old_los_by_lo)
  #   @old_records_counts = @old_los_by_lo.count
  #   step = 2
  #   Rails.logger.debug("*** Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
  #   @pairs_matched = Array.new
  #   step = 3
  #   Rails.logger.debug("*** Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
  #   lo_get_matches_for_new
  #   step = 4
  #   Rails.logger.debug("*** Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
  #   @exact_match_count = 0
  #   @update_as_equal_count = 0
  #   @selected_count = 0
  #   lo_process_pairs
  #   @pairs_filtered.each do |p|
  #     Rails.logger.debug("*** lo_process_pairs pairs: #{p[0][:lo_code]}, #{p[1][COL_OUTCOME_CODE]}, #{p[2][:lo_code]}, #{p[2][:total_match]}")
  #   end
  #   step = 5
  #   Rails.logger.debug("*** Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
  #   lo_deactivate_unmatched_old
  #   @pairs_filtered.each do |p|
  #     Rails.logger.debug("*** unsorted pairs: #{p[0][:lo_code]}, #{p[1][COL_OUTCOME_CODE]}, #{p[2][:lo_code]}, #{p[2][:total_match]}")
  #   end
  #   @pairs_filtered.sort_by! { |v| [v[2][:lo_code], -v[2][:total_match]]}
  #   # @pairs_filtered.sort_by! { |v| [v[2][:status], -v[2][:total_match]]}

  #   @pairs_filtered.each do |p|
  #     Rails.logger.debug("*** sorted pairs: #{p[0][:lo_code]}, #{p[1][COL_OUTCOME_CODE]}, [#{p[2][:lo_code]}, total_match: #{p[2][:total_match]}, selected: #{p[2][:selected]}, action: #{p[2][:action]}]")
  #   end
  #   last_exact_match = ''
  #   last_matched = ''
  #   last_matched_recs = 0
  #   last_matched_adds = 0
  #   last_matched_deact = 0

  #   Rails.logger.debug("*** @selected_pairs: #{@selected_pairs.inspect}")
  #   @pairs_filtered_n = Array.new
  #   # if there is an exact match
  #   # - remove all other options
  #   # Rails.logger.debug("*** Step #{step}")
  #   Rails.logger.debug("***")
  #   Rails.logger.debug("*** lo_matching_at_level @pairs_filtered loop. Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
  #   Rails.logger.debug("***")
  #   Rails.logger.debug("*** @exact_db_ids: #{@exact_db_ids}")
  #   @pairs_filtered.each do |p|
  #     rec_id = Integer(p[1][:rec_id]) rescue -1
  #     db_id = Integer(p[0][:db_id]) rescue -1
  #     # put db_id in match field for use in view
  #     p[2][:db_id] = db_id
  #     # Rails.logger.debug("*** rec_id: #{rec_id}, db_id: #{db_id}, codes(0,1,2): #{p[0][:lo_code]}, #{p[1][COL_OUTCOME_CODE]}, #{p[2][:lo_code]}, total match: #{p[2][:total_match]}, p2: #{p[2].inspect}")

  #     # If this new record has a selected pair, only output the selected pair for it (and corresponding unselect if not exact match)
  #     # does the new record in this pair have a selection made yet
  #     # if @selected_pairs[rec_id].present? || @deactivations.include?(db_id.to_s)
  #     if @selected_pairs[rec_id].present?
  #       # Rails.logger.debug("*** This is a new record has been matched already with pair: #{@selected_pairs[rec_id]}.")
  #       if @selected_pairs[rec_id] == p[2][:pair_id]
  #         # output the selected pair
  #         p[0][:matched] = p[1][:rec_id]
  #         @pairs_filtered_n << p
  #         # Rails.logger.debug("*** This is the matching pair: #{p.inspect}")

  #         # add an unselect pair if the matching is not exact
  #         if p[2][:total_match] != 6
  #           new_pair = [p[0].merge({action: :'x='}), p[1], get_matching_level({}, p[1]).merge({db_id: db_id*-1, action: :'x=', action_desc: 'unselect'})]
  #           @pairs_filtered_n << new_pair
  #           @unselect_count += 1
  #           # Rails.logger.debug("*** This creates the unselect for the matching pair id: #{new_pair.inspect}")
  #         end
  #       else
  #         # Rails.logger.debug("*** This is not the matching pair id: no output")

  #       end
  #     else
  #       # Rails.logger.debug("*** There is no matching pair, so output: #{p.inspect}")
  #       do_output_pair = true
  #       do_output_pair = false if db_id > 0 && @exact_db_ids.include?(db_id)
  #       @pairs_filtered_n << p if do_output_pair
  #     end

  #     Rails.logger.debug("*** @pairs_filtered_n.count: #{@pairs_filtered_n.count}")
  #     if p[2][:error].present?
  #       @error_count += 1
  #       Rails.logger.debug("*** @error_count incremented for #{p[2][:error]}")
  #       p[2][:selected] = nil
  #     end
  #   end
  #   @pairs_filtered = @pairs_filtered_n
  #   step = 6
  #   check_matching_counts
  #   @selected_pairs = Hash.new
  #   @selected_new_rec_ids = Array.new

  # end

end
