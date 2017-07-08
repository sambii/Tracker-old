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
        csv_hash[COL_OUTCOME_CODE] = (csv_hash[COL_OUTCOME_CODE].to_s).strip
        csv_hash[COL_OUTCOME_NAME] = (csv_hash[COL_OUTCOME_NAME].to_s).gsub(/\s+/, ' ').to_s.strip()[0...255]

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
        csv_hash[COL_MARK_PER] = all_mp_mask_str if (csv_hash[COL_MARK_PER].to_s).strip.upcase == 'YEAR LONG'

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


  # # removed these double checks (these are done by subject later) 7/7/2017 DT
  # # curriculum / LOs bulk upload file stage 2 processing - duplicate LO Code check
  # def validate_dup_lo_codes(records_in)
  #   Rails.logger.debug("*** validate_dup_lo_codes")
  #   records = records_in.clone
  #   err_rec_ix = 0
  #   begin
  #     error_list = Hash.new
  #     records.each_with_index do |rx, ix|
  #       err_rec_ix = ix
  #       # check all records following it for duplicated LO Code
  #       if !error_list[ix+2].present? || error_list[ix+2].present? && error_list[ix+2][0] != '-1'
  #         # only process records after the current record
  #         records.drop(ix+1).each_with_index do |ry, iy|
  #           iyall = iy + ix + 1 # index of the later row being tested
  #           # if later record has not been matched already, check if a match to current
  #           x_code = rx[COL_OUTCOME_CODE].present? ? rx[COL_OUTCOME_CODE] : rx[:lo_code]
  #           y_code = ry[COL_OUTCOME_CODE].present? ? ry[COL_OUTCOME_CODE] : ry[:lo_code]
  #           x_subject = rx[COL_SUBJECT].present? ? rx[COL_SUBJECT] : rx[:subject_id]
  #           y_subject = ry[COL_SUBJECT].present? ? ry[COL_SUBJECT] : ry[:subject_id]
  #           # if rx[COL_OUTCOME_CODE] == ry[COL_OUTCOME_CODE] && rx[COL_SUBJECT] == ry[COL_SUBJECT]
  #           if x_code == y_code && x_subject == y_subject
  #             # Rails.logger.debug("*** Match of #{ix+2} and #{iyall+2} !!!")
  #             # Rails.logger.debug("*** Match  rx: #{x_code}, #{x_subject} #{rx.inspect}")
  #             # Rails.logger.debug("*** Match  ry: #{y_code}, #{y_subject} #{ry.inspect}")
  #             if !error_list[iyall+2].present? || (error_list[iyall+2].present? && error_list[iyall+2][0] != '-1')
  #               # put or add to end the list of duplicated lines, but only if not listed prior
  #               # ix+2 or iyall+2 for zero relative ruby arrays and ignoring the header line.
  #               if error_list[ix+2].present?
  #                 error_list[ix+2][1] += ", #{iyall+2}"
  #               else
  #                 error_list[ix+2] = [rx[COL_OUTCOME_CODE], "#{ix+2}, #{iyall+2}"]
  #               end
  #               error_list[iyall+2] = ['-1', '']
  #             end
  #             # add the duplicate LO Code message to this row, if not there already
  #             records[ix][COL_ERROR] = append_with_comma(records[ix][COL_ERROR], 'Duplicate Code') if !(records[ix][COL_ERROR] ||= '').include?('Duplicate Code')
  #             # add the duplicate LO Code message to the later row, if not there already
  #             records[iyall][COL_ERROR] = append_with_comma(records[iyall][COL_ERROR], 'Duplicate Code') if !(records[iyall][COL_ERROR] ||= '').include?('Duplicate Code')
  #           end
  #         end
  #       end
  #     end
  #     Rails.logger.debug("*** error_list: #{error_list.inspect}")
  #     # remove lines matching lines removed with -1 value
  #     error_list.delete_if{|_,v| v[0] == '-1'}
  #     return {records: records, error_list: error_list, abort: false}
  #   rescue StandardError => e
  #     Rails.logger.error("ERROR: validate_dup_lo_codes record #{err_rec_ix} ")
  #     return {records: records, error_list: error_list, abort: true}
  #   end
  # end


  # # removed these double checks (these are done by subject later) 7/7/2017 DT
  # # curriculum / LOs bulk upload file stage 2 processing - duplicate LO Code check
  # def validate_dup_lo_descs(records_in)
  #   records = records_in.clone
  #   begin
  #     error_list = Hash.new
  #     records.each_with_index do |rx, ix|
  #       # check all records following it for duplicated LO description
  #       if !error_list[ix+2].present? || error_list[ix+2].present? && error_list[ix+2][0] != '-1'
  #         records.drop(ix+1).each_with_index do |ry, iy|
  #           iyall = iy + ix + 1 # index of the later row being tested
  #           # if later record has not been matched already, check if a match to current
  #           x_desc = rx[COL_OUTCOME_NAME].present? ? rx[COL_OUTCOME_NAME] : rx[:desc]
  #           y_desc = ry[COL_OUTCOME_NAME].present? ? ry[COL_OUTCOME_NAME] : ry[:desc]
  #           x_subject = rx[COL_SUBJECT].present? ? rx[COL_SUBJECT] : rx[:subject_id]
  #           y_subject = ry[COL_SUBJECT].present? ? ry[COL_SUBJECT] : ry[:subject_id]
  #           # if rx[COL_OUTCOME_NAME] == ry[COL_OUTCOME_NAME] && rx[COL_SUBJECT] == ry[COL_SUBJECT]
  #           if x_desc == y_desc && x_subject == y_subject
  #             # Rails.logger.debug("*** Match of #{ix+2} and #{iyall+2} !!!")
  #             # Rails.logger.debug("*** Match  rx: #{x_desc}, #{x_subject} #{rx.inspect}")
  #             # Rails.logger.debug("*** Match  ry: #{y_desc}, #{y_subject} #{ry.inspect}")
  #             # Rails.logger.debug("*** Match of #{ix+2} and #{iyall+2} !!!")
  #             if !error_list[iyall+2].present? || (error_list[iyall+2].present? && error_list[iyall+2][0] != '-1')
  #               # put or add to end the list of duplicated lines, but only if not listed prior
  #               # ix+2 or iyall+2 for zero relative ruby arrays and ignoring the header line.
  #               if error_list[ix+2].present?
  #                 error_list[ix+2][1] += ", #{iyall+2}"
  #               else
  #                 error_list[ix+2] = [rx[COL_OUTCOME_NAME], "#{ix+2}, #{iyall+2}"]
  #               end
  #               error_list[iyall+2] = ['-1', '']
  #             end
  #             # Rails.logger.debug("*** dup description added for #{ix}, #{records[ix].inspect}")
  #             # Rails.logger.debug("*** dup description added for #{iyall}, #{records[iyall].inspect}")
  #             # add the duplicate LO Description message to this row, if not there already
  #             records[ix][COL_ERROR] = append_with_comma(records[ix][COL_ERROR], 'Duplicate Description') if !(records[ix][COL_ERROR] ||= '').include?('Duplicate Description')
  #             # add the duplicate LO Description message to the later row, if not there already
  #             records[iyall][COL_ERROR] = append_with_comma(records[iyall][COL_ERROR], 'Duplicate Description') if !(records[iyall][COL_ERROR] ||= '').include?('Duplicate Description')
  #           end
  #         end
  #       end
  #     end
  #     Rails.logger.debug("*** error_list: #{error_list.inspect}")
  #     # remove lines matching lines removed with -1 value
  #     error_list.delete_if{|_,v| v[0] == '-1'}
  #     return {records: records, error_list: error_list, abort: false}
  #   rescue StandardError => e
  #     return {records: records, error_list: error_list, abort: true}
  #   end
  # end

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
      rec = Hash.new
      rec[:rec_id] = Integer(pnew[:rec_id]) rescue 0
      rec[:subject_id] = Integer(pnew[:subject_id]) rescue 0
      rec[:'Course'] = pnew['Course']
      rec[:'Grade'] = pnew['Grade']
      rec[:'mp_bitmap'] = pnew['mp_bitmap']
      rec[:'LO Code:'] = pnew['LO Code:']
      rec[:'Learning Outcome'] = pnew['Learning Outcome']
      rec[:error] =  nil
      records << rec
      new_los_by_rec[pnew[:rec_id]] = rec
      new_los_by_lo_code[pnew[:lo_code]] = rec
    end if  params['r'].present?
    return {records: records, los_by_rec: new_los_by_rec, new_los_by_lo_code: new_los_by_lo_code}
  end

  def lo_get_file_from_upload(params)
    # no initial errors, process file
    new_los_by_rec = Hash.new
    new_los_by_lo_code = Hash.new
    records = Array.new
    inval_subject_names = Hash.new
    @filename = params['file'].original_filename
    # @errors[:filename] = 'Choose file again to rerun'
    # note: 'headers: true' uses column header as the key for the name (and hash key)
    new_los_by_rec = Hash.new
    ix = 0 # record number (ignore other subject records if matching subject)
    CSV.foreach(params['file'].path, headers: true) do |row|
      rhash = validate_csv_fields(row.to_hash.with_indifferent_access, @subject_names)
      rhash[COL_REC_ID] = ix
      if rhash[COL_ERROR]
        @errors[:base] = 'Errors exist:' if !rhash[COL_EMPTY]
      end
      # check if course and grade match an existing subject name
      check_subject = rhash[COL_SUBJECT]
      if @subject_names[check_subject].blank?
        check_subject = rhash[:'Course'].to_s + ' ' + rhash[:'Grade'].to_s
      end
      have_all_mps = true
      if @subject_names[check_subject].blank?
        # no matching standard course + grade, check if has semester in name
        rhash[:'mp_bitmap'].to_s.split('&').each do |one_mp|
          have_all_mps = false if @subject_names[check_subject + 's' + one_mp].blank?
        end
      end
      if !have_all_mps
        # cannot find matching course with or without semester in names
        inval_subject_names[check_subject] = check_subject
      end
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
    # Rails.logger.debug("*** lo_get_file_from_upload @present_by_subject: #{@present_by_subject.inspect}")
    # Rails.logger.debug("*** lo_get_file_from_upload records.count == 0: #{records.count == 0}")
    # this test doesn't work, @present_by_subject is not set yet
    # raise("Error - No Curriculum Records to upload.") if records.count == 0 && @present_by_subject.blank?
    return {records: records, new_los_by_rec: new_los_by_rec, new_los_by_lo_code: new_los_by_lo_code, inval_subject_names: inval_subject_names}
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

  def lo_get_old_los_for_subj(subj)
    # update old records in all_old_los for this subject
    @old_db_ids_by_subject[subj.id].each do |db_id|
      old_rec = @all_old_los[db_id]
      if old_rec.present?
        updated_old_rec = SubjectOutcome.includes(:subject).find(db_id)
        # Rails.logger.debug("*** Update old rec: original: #{old_rec.inspect} updated_old_rec: #{updated_old_rec.inspect}")
        if updated_old_rec.errors.count == 0 && updated_old_rec.present?
          old_rec[:lo_code] = updated_old_rec[:lo_code]
          old_rec[:desc] = updated_old_rec[:description]
          old_rec[:mp] = updated_old_rec[:marking_period]
          old_rec[:active] = updated_old_rec[:active]
        else
          old_rec[:error] = old_rec[:error].present? ? old_rec[:error]+', Update error' : 'Update error'
          Rails.logger.error("*** count_errors increased - get old rec: original: #{old_rec.inspect} updated_old_rec: #{updated_old_rec.inspect}, errors: #{updated_old_rec.errors.full_messages}")
          @count_errors += 1
          @error_details[db_id] = so.errors.full_messages
        end
        # Rails.logger.debug("*** Updated old rec: #{old_rec.inspect}")
      else
          Rails.logger.error("*** count_errors increased - get old rec: db_id: #{db_id},  missing old rec")
        @count_errors += 1
        @error_details[db_id] = "Missing record to update: #{db_id}"
      end
    end
  end

  def lo_get_all_new_los(records)
    # Rails.logger.debug("*** @subject_ids: #{@subject_ids.inspect}")
    new_rec_ids_by_subject = Hash.new([])
    all_new_los = Hash.new
    invalid_subject_names = Hash.new
    records.each do |rec|
      # Rails.logger.debug("*** lo_get_all_new_los rec: #{rec.inspect}")
      # fix for two different formats coming in:
      lo_code = rec[:lo_code].present? ? rec[:lo_code] : rec[:'LO Code:']
      lo_desc = rec[:desc].present? ? rec[:desc] : rec[:'Learning Outcome']
      lo_course = rec[:course].present? ? rec[:course] : rec[:'Course']
      lo_grade = rec[:grade].present? ? rec[:grade] : rec[:'Grade']
      lo_mp = rec[:mp].present? ? rec[:mp] : rec[:mp_bitmap]
      # check for valid subject
      subject_id = Integer(rec[:subject_id]) rescue 0
      if subject_id > 0 && @subject_ids[subject_id].present?
        # we have a matched subject name
        subject_name = @subject_ids[subject_id].name
      else
        # create the standard course & grade name and if not found add to invalid subjects.
        subject_name = "#{lo_course} #{lo_grade}"
        if @subject_names[subject_name].present?
          subject_id = @subject_names[subject_name].id
        else
          subject_id = 0
          invalid_subject_names[subject_name] = subject_name
        end
      end
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
    return {new_rec_ids_by_subject: new_rec_ids_by_subject, all_new_los: all_new_los, invalid_subject_names: invalid_subject_names}
  end

  # update @error_list for duplicate code and descriptions for a subject.
  def lo_dups_for_subject(subj)
    new_rec_ids = @new_rec_ids_by_subject[subj.id].present? ? @new_rec_ids_by_subject[subj.id] : []
    Rails.logger.debug("*** new_rec_ids: #{new_rec_ids.inspect}")
    subj_flags = @subj_to_proc[subj.id].present? ? @subj_to_proc[subj.id] : {}
    subj_flags = subj_flags.merge({error: false})  # assume no duplicate errors

    @error_list = Hash.new
    records = Array.new
    new_rec_ids.each do |rec_id|
      records << @all_new_los[rec_id]
    end
    records.each_with_index do |rx, ix|
      # check all records following it for duplicated LO description
      if !@error_list[ix+2].present? || @error_list[ix+2].present? && @error_list[ix+2][0] != '-1'
        records.drop(ix+1).each_with_index do |ry, iy|
          iyall = iy + ix + 1 # index of the later row being tested
          # if later record has not been matched already, check if a match to current
          x_desc_1 = rx[COL_OUTCOME_NAME].present? ? rx[COL_OUTCOME_NAME] : rx[:desc]
          x_desc_2 = (x_desc_1.present?) ? x_desc_1.gsub(/\s+/, ' ').strip() : ''
          y_desc_1 = ry[COL_OUTCOME_NAME].present? ? ry[COL_OUTCOME_NAME] : ry[:desc]
          y_desc_2 = (y_desc_1.present?) ? y_desc_1.gsub(/\s+/, ' ').strip() : ''
          x_code = rx[COL_OUTCOME_CODE].present? ? rx[COL_OUTCOME_CODE] : rx[:lo_code]
          y_code = ry[COL_OUTCOME_CODE].present? ? ry[COL_OUTCOME_CODE] : ry[:lo_code]
          x_subject = rx[COL_SUBJECT].present? ? rx[COL_SUBJECT] : rx[:subject_id]
          y_subject = ry[COL_SUBJECT].present? ? ry[COL_SUBJECT] : ry[:subject_id]
          if x_desc_2 == y_desc_2 && x_subject == y_subject
            set_error_list_matches(ix, iyall, 'description')
            # add the duplicate LO Description message to this row, if not there already
            records[ix][COL_ERROR] = append_with_comma(records[ix][COL_ERROR], 'Duplicate Description') if !(records[ix][COL_ERROR] ||= '').include?('Duplicate Description')
            # add the duplicate LO Description message to the later row, if not there already
            records[iyall][COL_ERROR] = append_with_comma(records[iyall][COL_ERROR], 'Duplicate Description') if !(records[iyall][COL_ERROR] ||= '').include?('Duplicate Description')
          end
          if x_code == y_code && x_subject == y_subject
            set_error_list_matches(ix, iyall, x_code)
            # add the duplicate Code message to this row, if not there already
            records[ix][COL_ERROR] = append_with_comma(records[ix][COL_ERROR], 'Duplicate Code') if !(records[ix][COL_ERROR] ||= '').include?('Duplicate Code')
            # add the duplicate Code message to the later row, if not there already
            records[iyall][COL_ERROR] = append_with_comma(records[iyall][COL_ERROR], 'Duplicate Code') if !(records[iyall][COL_ERROR] ||= '').include?('Duplicate Code')
          end
        end # records.drop(ix+1).each_with_index
      end # if !@error_list[ix+2].present?  ...
    end # records.each_with_index
  end

  def set_error_list_matches(ix, iyall, label)
    Rails.logger.debug("*** Match of #{ix+2} and #{iyall+2} !!!")
    if !@error_list[iyall+2].present? || (@error_list[iyall+2].present? && @error_list[iyall+2][0] != '-1')
      if @error_list[ix+2].present?
        @error_list[ix+2][1] += ", #{iyall+2}"
      else
        @error_list[ix+2] = [label, "#{ix+2}, #{iyall+2}"]
      end
      @error_list[iyall+2] = ['-1', '']
    end
  end

  # updates @all_old_los and @all_new_los for subject subj
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
    subj_flags = @subj_to_proc[subj.id].present? ? @subj_to_proc[subj.id] : {}
    subj_flags = subj_flags.merge({process: true})  # assume automatically processing possible unless reset

    new_rec_ids.each do |rec_id|
      new_rec = @all_new_los[rec_id]
      # Rails.logger.debug("*** new_rec: #{new_rec.inspect}")
      if new_rec[:error].present? # was an error in the duplicates checking
        dup_error_count += 1
        subj_flags[:error] = true
        # there is an error, cannot automatically process
        subj_flags[:process] = false
      end
      desc_new = (new_rec[:desc].present?) ? new_rec[:desc].gsub(/\s+/, ' ').strip() : ''
      old_db_ids.each do |db_id|
        old_rec = @all_old_los[db_id]
        # Rails.logger.debug("*** old_rec: #{old_rec.inspect}")
        desc_old = (old_rec[:desc].present?) ? old_rec[:desc].gsub(/\s+/, ' ').strip() : ''
        if !new_rec[:error].blank?
          subj_flags[:error] = true
          # there is an error, cannot automatically process
          subj_flags[:process] = false
        end
        # if new_rec[:error].blank? && desc_new == desc_old
        if desc_new == desc_old
          if new_rec[:exact_match] && new_rec[:exact_match][:old_rec_active]
            # We already have an exact match that is active, dont select any others
          else
            matching_h = {key: old_rec[:match_id], descr: "#{old_rec[:match_id]}-#{old_rec[:lo_code]}", val: MAX_DESC_LEVEL, db_id: old_rec[:db_id], rec_id: new_rec[:rec_id], old_rec_active: old_rec[:active]}
            new_rec[:exact_match] = matching_h
            old_rec[:exact_match] = matching_h
            new_rec[:matches] = nil
          end
        end
      end
      # Rails.logger.debug("*** after matching new_rec: #{new_rec.inspect}")
    end

    Rails.logger.debug("*** pre check subj_flags.inspect: #{subj_flags.inspect}")

    db_deact_count = 0
    db_active_count = 0
    new_rec_ids.each do |rec_id|
      new_rec = @all_new_los[rec_id]
      # Rails.logger.debug("*** new_rec[:exact_match]: #{new_rec[:exact_match].inspect}, #{new_rec.inspect}")
      # subj_flags[:process] = false if new_rec[:exact_match].blank?
      if new_rec[:exact_match].present?
        if new_rec[:exact_match][:old_rec_active]
          exact_active_count += 1
        else
          exact_deact_count += 1
        end
        exact_count += 1
      end
    end
    old_db_ids.each do |db_id|
      old_rec = @all_old_los[db_id]
      if old_rec[:active]
        db_active_count += 1
      else
        db_deact_count += 1
      end
      # subj_flags[:process] = false if old_rec[:exact_match].blank?
    end

    if new_rec_ids.count > exact_count && exact_active_count < db_active_count
      # some new records are not exactly matched and there are some active database records that are not exactly matched
      # we must present the matches to the user to choose (not automatically processable)
      subj_flags[:process] = false
    end

    Rails.logger.debug("*** #{db_active_count == exact_active_count} - db_active_count: #{db_active_count} ?=? exact_active_count: #{exact_active_count}")
    Rails.logger.debug("*** #{db_deact_count == exact_deact_count} - db_deact_count: #{db_deact_count} ?>=? exact_deact_count: #{exact_deact_count}")

    Rails.logger.debug("*** subj_flags[:add_only]: #{subj_flags[:add_only]}")
    Rails.logger.debug("*** subj_flags.inspect: #{subj_flags.inspect}")
    Rails.logger.debug("*** Subject: #{subj.id}-#{subj.name}")
    Rails.logger.debug("*** Old Count: #{old_db_ids.count}")
    Rails.logger.debug("*** New Count: #{new_rec_ids.count}")
    Rails.logger.debug("*** exact_count: #{exact_count}")
    Rails.logger.debug("*** subj_flags: #{subj_flags.inspect}")
    @subj_to_proc[subj.id] = subj_flags
  end

  def lo_set_matches(new_recs_in, old_recs_in, old_db_ids_by_subject, all_old_los)
    step = 6
    Rails.logger.debug("*** Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
    # next set matching values for non exact matches
    new_recs_in.each do |new_rec|
      # Rails.logger.debug("*** lo_set_matches new rec: #{new_rec.inspect}")
      subject_id = new_rec[:subject_id]
      rec_proc_count = 0
      if new_rec[:exact_match].blank?
        subj_ids = old_db_ids_by_subject[subject_id].present? ? old_db_ids_by_subject[subject_id] : []
        subj_ids.each do |old_db_id|
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
    updates_done = false
    Rails.logger.debug("*** lo_update_subject #{subj.id}-#{subj.name}")
    # update subject new records and deactivate extra old records
    new_rec_ids = @new_rec_ids_by_subject[subj.id].present? ? @new_rec_ids_by_subject[subj.id] : []
    subj_errors_count = 0
    new_rec_ids.each do |rec_id|
      new_rec = @all_new_los[rec_id]
      # Rails.logger.debug("*** New rec to update: #{new_rec.inspect}")
      if new_rec[:exact_match].present?
        db_id = new_rec[:exact_match][:db_id]
        old_rec = @all_old_los[db_id]
        # Rails.logger.debug("*** matching Old rec: #{db_id} - #{old_rec.inspect}")
        updates_done = true if lo_update(new_rec, old_rec)
        Rails.logger.debug("*** subject  #{subj.id}-#{subj.name} lo_update updates_done: #{updates_done}")
      else
        updates_done = true if lo_add(new_rec)
        Rails.logger.debug("*** subject  #{subj.id}-#{subj.name} lo_add updates_done: #{updates_done}")
      end
    end
    # Deactivate all old records that are not :up_to_date
    if subj_errors_count == 0
      updates_done = true if lo_deact_rest_old_recs(subj)
      Rails.logger.debug("*** subject  #{subj.id}-#{subj.name} lo_deact_rest_old_recs updates_done: #{updates_done}")
    end
    if subj_errors_count > 0
      @subj_to_proc[subj.id][:error] = true
    end
    Rails.logger.debug("*** subject  #{subj.id}-#{subj.name} return updates_done: #{updates_done}")
    return updates_done
  end

  def lo_update(new_rec, old_rec)
    update_done = false
    if new_rec[:error].blank?
      if new_rec[:lo_code] != old_rec[:lo_code] || new_rec[:desc].gsub(/\r\n?/, "\n").strip() != old_rec[:desc].gsub(/\r\n?/, "\n").strip() || new_rec[:mp] != old_rec[:mp] || !old_rec[:active]
        # Rails.logger.debug("*** diff in records")
        # Rails.logger.debug("*** diff lo_code: #{new_rec[:lo_code]} != #{old_rec[:lo_code]}") if new_rec[:lo_code] != old_rec[:lo_code]
        # Rails.logger.debug("*** diff desc: #{new_rec[:desc].inspect}") if new_rec[:desc].gsub(/\r\n?/, "\n").strip() != old_rec[:desc].gsub(/\r\n?/, "\n").strip()
        # Rails.logger.debug("*** diff desc: #{old_rec[:desc].inspect}") if new_rec[:desc].gsub(/\r\n?/, "\n").strip() != old_rec[:desc].gsub(/\r\n?/, "\n").strip()
        # Rails.logger.debug("*** diff mp: #{new_rec[:mp]} != #{old_rec[:mp]}") if new_rec[:mp] != old_rec[:mp]
        # Rails.logger.debug("*** not active: #{old_rec[:active]}") if !old_rec[:active]
        so = SubjectOutcome.find(old_rec[:db_id])
        so.active = true
        so.lo_code = new_rec[:lo_code]
        so.description = new_rec[:desc]
        so.marking_period = new_rec[:mp]
        so.save
        if so.errors.count > 0
          Rails.logger.error("*** count_errors increased - lo_update **** Error updating : #{so.inspect}, #{so.errors.full_messages}")
          old_rec[:error] = so.errors.full_messages
          @count_errors += 1
          @error_details[old_rec[:db_id]] = "#{new_rec[:subject_id]}-#{new_rec[:subject_name]}, new LO code: #{new_rec[:lo_code]} Error: #{so.errors.full_messages.join}"
        else
          new_rec[:up_to_date] = true
          old_rec[:up_to_date] = true
          Rails.logger.debug("*** lo_update **** Updated to : #{so.inspect}")
          @count_updates += 1
        end
        Rails.logger.debug("*** lo_update **** update_done: #{update_done}")
        update_done = true
      else
        new_rec[:up_to_date] = true
        old_rec[:up_to_date] = true
        Rails.logger.debug("*** lo_update **** already up to date")
      end
    else
      Rails.logger.debug("*** lo_update **** error: #{new_rec[:error]}")
    end
    return update_done
  end

  def lo_add(new_rec)
    # this new record is to be added
    so = SubjectOutcome.new
    so.active = true
    so.subject_id = new_rec[:subject_id]
    so.lo_code = new_rec[:lo_code]
    so.description = new_rec[:desc]
    so.marking_period = new_rec[:mp]
    so.save
    if so.errors.count > 0
      Rails.logger.error("*** lo_add **** count_errors increased - Error adding : #{so.inspect}, #{so.errors.full_messages}")
      new_rec[:error] = so.errors.full_messages
      @count_errors += 1
      @error_details["nr_#{count_errors}"] = so.errors.full_messages
    else
      new_rec[:up_to_date] = true
      # Rails.logger.debug("*** lo_add **** Added : #{so.inspect}")
      @count_adds += 1
    end
    return true
  end

  def lo_deact_rest_old_recs(subj)
    update_done = false
    # Deactivate all old records that are not :up_to_date
    # Rails.logger.debug("*** subj: #{subj} - #{subj.inspect}")
    old_db_ids = @old_db_ids_by_subject[subj.id].present? ? @old_db_ids_by_subject[subj.id] : []
    old_db_ids.each do |db_id|
      old_rec = @all_old_los[db_id]
      Rails.logger.debug("*** old_rec: #{db_id} - #{old_rec.inspect}")
      Rails.logger.debug("TTTTT deactivate record? :up_to_date => #{old_rec[:up_to_date]}, :active => #{old_rec[:active]}")
      if (old_rec[:up_to_date].blank? || old_rec[:up_to_date] == false) && old_rec[:active] == true
        Rails.logger.debug("TTTTT deactivate record!!!")
        db_id = old_rec[:db_id]
        so = SubjectOutcome.find(db_id)
        # Rails.logger.debug("*** Before Deactivation : #{so.inspect}")
        so.active = false
        so.save
        if so.errors.count > 0
          subj_errors_count += 1
          Rails.logger.error("*** count_errors increased - lo_deact_rest_old_recs **** Error updating : #{so.inspect}, #{so.errors.full_messages}")
          old_rec[:error] = so.errors.full_messages
          @count_errors += 1
          @error_details[db_id] = so.errors.full_messages
        else
          old_rec[:up_to_date] = true
          # Rails.logger.debug("*** lo_deact_rest_old_recs **** Deactivated : #{so.inspect}")
          @count_deactivates += 1
        end
        update_done = true
      end
    end
    return update_done
  end

  def lo_setup_subject(subj, auto_update)
    # Rails.logger.debug("*** lo_setup_subject 1 @subj_to_proc[subj.id]: #{@subj_to_proc[subj.id]}")
    lo_dups_for_subject(subj)
    # Rails.logger.debug("*** lo_setup_subject 2 @subj_to_proc[subj.id]: #{@subj_to_proc[subj.id]}")
    lo_matches_for_subject(subj)
    # Rails.logger.debug("*** lo_setup_subject 3 @subj_to_proc[subj.id]: #{@subj_to_proc[subj.id]}")
    if @subj_to_proc[subj.id][:process] && !@subj_to_proc[subj.id][:error]
      Rails.logger.debug("*** lo_setup_subject - Auto Update possible - #{subj.inspect}")
      if auto_update
        Rails.logger.debug("*** lo_setup_subject - AUTO UPDATE - #{subj.inspect}")
        # update this subject now and be done with it
        Rails.logger.debug("TTTTT *** lo_setup_subject - old @count_updated_subjects:  #{@count_updated_subjects}")
        @count_updated_subjects += 1 if lo_update_subject(subj)
        Rails.logger.debug("TTTTT *** lo_setup_subject - updated @count_updated_subjects:  #{@count_updated_subjects}")
      else
        Rails.logger.debug("*** lo_setup_subject - no autoupdate, then display it (if first) #{subj.inspect} -> #{@subject_to_show.inspect}")
        # if no autoupdate, then display it (if first)
        @subject_to_show = subj if @subject_to_show.blank?
      end
    else
      Rails.logger.debug("*** lo_setup_subject - DONT AUTO UPDATE - #{subj.inspect}")
      # This is a subject that must be matched, set up first presenting subject if not done already
      if @subject_to_show.blank?
        @subject_to_show = subj
      end
    end
  end

end
