# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SubjectOutcomesController < ApplicationController

  include SubjectOutcomesHelper

  def index
    #
    # todo - remove this code - dead code - uses with_permissions_to from declarative_authorization gem
    @subject_outcomes = SubjectOutcome.with_permissions_to :read
  end

  def new
    @subject_outcome = SubjectOutcome.new
    @subjects = Subject.all
  end

  def create
    @subject_outcome = SubjectOutcome.new(params[:subject_outcome])
    @subjects = Subject.all #with_permissions_to(:manage_subject_outcomes)
    respond_to do |format|
      if @subject_outcome.save
        format.html { redirect_to new_section_outcome_path(:section_id => params[:section_id]) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @subject_outcome = SubjectOutcome.find_by_id(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def update
    @subject_outcome = SubjectOutcome.find_by_id(params[:id])

    respond_to do |format|
      if @subject_outcome.update_attributes(params[:subject_outcome])
        format.html { redirect_to session[:return_to], :notice => 'Learning Outcome was successfully updated.' }
      else
        format.html { render :action => :edit }
      end
    end
  end


  # new UI, upload LOs from curriculum spreadsheet to Model School (for new year rollover)
  # new UI HTML post method
  # Bulk Upload LOs file
  # stage 2 - reads csv file in and errors found within spreadsheet
  # stage 3 - reads csv file in and errors found against database
  # stage 4 - reads csv file and performs model validation of each record
  # stage 5 - updates records within a transaction - can upload again if errors
  # see app/helpers/users_helper.rb for helper functions
  def upload_lo_file
    authorize! :upload_lo, SubjectOutcome
    step = 0
    begin

      first_display = (request.method == 'GET' && params['utf8'].blank?)

      @stage = 1
      @records = Array.new
      @errors = Hash.new
      @selections = Hash.new
      @selection_params = Hash.new
      @deactivations = Array.new
      @selected_pairs = Hash.new
      @selected_new_rec_ids = Array.new
      @error_details = Hash.new

      @inactive_old_count = 0
      action_count = 0

      # array of old and new records to present to the user
      @new_los_to_present = Array.new
      @old_los_to_present = Array.new
      @present_by_subject = nil
      @subject_to_show = nil

      # get the model school
      @school = lo_get_model_school(params)
      # get the subjects for the model school
      @subjects = Subject.where(school_id: @school.id).includes(:discipline).order('disciplines.name, subjects.name')
      # if only processing one subject
      # - creates/updates @match_subject, @subject_id
      @match_subject = lo_get_match_subject(params)

      # ensure that model_lo_id is preset
      so_count = SubjectOutcome.where('model_lo_id IS NOT NULL').count
      Rails.logger.debug("*** so_count: #{so_count}")
      if so_count == 0
        # ensure model_lo_id fields in subject outcomes for all schools are preset to model school subject outcomes.
        School.all.each do |s|
          if s.id != @school.id
            Rails.logger.debug("*** process School: #{s.id} - #{s.name}")
            # only do this for schools not the model school
            s.preset_model_lo_id
            Rails.logger.debug("*** process School done")
          end
        end
      end


      if params['file'].blank? && !first_display
        @errors[:filename] = "Error: Missing Curriculum (LOs) Upload File."
        raise @errors[:filename]
      end

      if first_display
        @errors[:filename] = "Info: First Display"
        raise @errors[:filename]
      end

      @stage = 2
      step = 0
      Rails.logger.debug("*** upload_lo_file Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")

      Rails.logger.debug("*** create subject hashes")
      @subject_ids = Hash.new
      @subject_names = Hash.new
      @subjects.each do |s|
        # do all subjects if @subject_id not present, otherwise do the selected subject
        @subject_ids[s.id] = s if !@subject_id.present? || (@subject_id.present? && @subject_id == s.id) # IDs of all subjects to process
        @subject_names[s.name] = s
      end

      step = 1
      Rails.logger.debug("*** upload_lo_file Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # create hash of new LO records from uploaded csv file
      recs_from_upload = lo_get_file_from_upload(params)
      @records = recs_from_upload[:records]

      # Rails.logger.debug("*** @records: #{@records.inspect}")
      @new_los_by_rec_clean = recs_from_upload[:new_los_by_rec]
      # Rails.logger.debug("*** @new_los_by_rec_clean: #{@new_los_by_rec_clean.inspect}")
      @new_los_by_lo_code_clean = recs_from_upload[:new_los_by_lo_code]
      # Rails.logger.debug("*** @new_los_by_lo_code_clean: #{@new_los_by_lo_code_clean.inspect}")
      inval_subject_names = recs_from_upload[:inval_subject_names]
      # Rails.logger.debug("*** inval_subject_names: #{inval_subject_names.inspect}")
      @errors[:base] = append_with_comma(@errors[:base], "Invalid subject(s): #{inval_subject_names.map {|k,v| v}.join(', ')}") if inval_subject_names.count > 0

      step = 2
      Rails.logger.debug("*** upload_lo_file Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # Check for duplicate LO codes in uploaded file
      @error_list = Hash.new
      # check for file duplicate LO Codes
      dup_lo_code_checked = validate_dup_lo_codes(@records)
      @error_list = dup_lo_code_checked[:error_list]
      Rails.logger.debug("*** @error_list: #{@error_list.inspect}")
      @records = dup_lo_code_checked[:records]
      Rails.logger.debug("*** records count: #{@records.count}")
      @errors[:base] = 'Errors exist!!!:' if dup_lo_code_checked[:abort] || @error_list.length > 0


      step = 3
      Rails.logger.debug("*** upload_lo_file Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # Check for duplicate LO descriptions in uploaded file
      @error_list2 = Hash.new
      # check for file duplicate LO Descriptions
      dup_lo_descs_checked = validate_dup_lo_descs(@records)
      @error_list2 = dup_lo_descs_checked[:error_list]
      Rails.logger.debug("*** @error_list2: #{@error_list2.inspect}")
      @records = dup_lo_descs_checked[:records]
      @records_clean = @records.clone
      Rails.logger.debug("*** records count: #{@records.count}")
      # @errors[:base] = 'Errors exist - see below!!!:' if dup_lo_descs_checked[:abort] || @error_list2.length > 0
      # Rails.logger.debug("*** rec 0: #{@records[0]}")
      # Rails.logger.debug("*** rec 1: #{@records[1]}")
      # Rails.logger.debug("*** rec 2: #{@records[2]}")
      # Rails.logger.debug("*** rec 3: #{@records[3]}")
      # Rails.logger.debug("*** rec 4: #{@records[4]}")

      Rails.logger.debug("*** @errors: #{@errors.inspect}")

      @stage = 3
      step = 0
      Rails.logger.debug("*** upload_lo_file Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # @new_recs_to_process = lo_get_new_recs_to_process(@records)

      step = 1
      # get the subject outcomes from the database by subject
      saved_old_los = lo_get_all_old_los
      @old_db_ids_by_subject = saved_old_los[:old_db_ids_by_subject].clone
      @all_old_los = saved_old_los[:all_old_los].clone

      step = 2
      Rails.logger.debug("*** upload_lo_file Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # get the subject outcomes from the upload by subject
      new_los = lo_get_all_new_los(@records)
      @new_rec_ids_by_subject = new_los[:new_rec_ids_by_subject].clone
      @all_new_los = new_los[:all_new_los].clone
      invalid_subject_names = new_los[:invalid_subject_names].clone
      @errors[:base] = append_with_comma(@errors[:base], "Invalid subject(s): #{invalid_subject_names.map {|k,v| v}.join(', ')}") if invalid_subject_names.count > 0 && inval_subject_names.count == 0

      step = 3
      Rails.logger.debug("*** Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # @errors = Hash.new

      step = 4
      Rails.logger.debug("*** lo_upload Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # hash to determine if subject should be processed or matched (by subject id)
      @subj_to_proc = Hash.new({})


      @prior_subject = nil
      @count_errors = 0
      @count_updates = 0
      @count_adds = 0
      @count_deactivates = 0
      @count_updated_subjects = 0

      Rails.logger.debug("*** starting @match_subject #{@match_subject.inspect}")

      # get starting subject to present to user
      if @match_subject.present?
        lo_setup_subject(@match_subject, false)
        @subject_to_show = @match_subject # always show match subject if subject has been chosen
        @prior_subject_name = ''
      else
        Rails.logger.debug("*** @all_new_los.count #{@all_new_los.count}")
        raise("Error - No Curriculum Records to upload.") if @all_new_los.count == 0
        @subjects.each do |subj|
          lo_setup_subject(subj, true)
          break if @subject_to_show.present?
        end
        @present_by_subject = @subject_to_show
        @prior_subject_name = 'Automatically Updated Subjects'
      end
      Rails.logger.debug("*** @subject_to_show #{@subject_to_show.inspect}")
      Rails.logger.debug("*** @present_by_subject #{@present_by_subject.inspect}")
      @no_update = @subject_to_show.present? ? @subj_to_proc[@subject_to_show.id][:skip] : true
      Rails.logger.debug("*** @no_update #{@no_update.inspect}")
      Rails.logger.debug("*** @allow_save_all #{@allow_save_all}")
      Rails.logger.debug("*** @errors.count #{@errors.count}")
      Rails.logger.debug("*** @count_errors #{@count_errors}")
      Rails.logger.debug("*** @count_updates #{@count_updates}")
      Rails.logger.debug("*** @count_adds #{@count_adds}")
      Rails.logger.debug("*** @count_deactivates #{@count_deactivates}")

      @total_errors = @count_errors
      @total_updates = @count_updates
      @total_adds = @count_adds
      @total_deactivates = @count_deactivates
      @total_deactivates = @count_deactivates

      Rails.logger.debug("*** Subject to Present to User: #{@subject_to_show.inspect}")
      if @subject_to_show.present?
        step = '6a'
        Rails.logger.debug("*** Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
        # we are processing one subject, so we are not looping through subjects
        # pull the new learning outcomes to process from the @new_rec_ids_by_subject
        @new_rec_ids_by_subject[@subject_to_show.id].each do |rec_id|
          @new_los_to_present << @all_new_los[rec_id]
        end
        step = '6b'
        Rails.logger.debug("*** Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
        # pull the old learning outcomes to process from the @old_db_ids_by_subject
        old_db_ids = @old_db_ids_by_subject[@subject_to_show.id]
        old_db_ids = [] if old_db_ids.blank?
        old_db_ids.each do |db_id|
          @old_los_to_present << @all_old_los[db_id]
        end

        lo_set_matches(@new_los_to_present, @old_los_to_present, @old_db_ids_by_subject, @all_old_los)

      else
        # all processing done, skip to report
        @stage = 10
      end

    rescue => e
      if @errors[:filename] == "Info: First Display"
        @errors[:filename] = nil
        # Ignore this, first display where user is asked filename
      else
        msg_str = "ERROR: lo_upload Exception at @stage: #{@stage}, step #{step}, item #{action_count+1} - #{e.message}"
        @errors[:base] = append_with_comma(@errors[:base], msg_str)
        Rails.logger.error(msg_str)
        flash[:alert] = msg_str[0...50]
        @stage = 5
      end
    end

    # @old_los_to_present.each{|rec| Rails.logger.debug("*** present old rec: #{rec}")}
    # @new_los_to_present.each{|rec| Rails.logger.debug("*** present new rec: #{rec}")}

    Rails.logger.debug("*** @present_by_subject #{@present_by_subject.inspect}")
    Rails.logger.debug("*** @errors #{@errors.inspect}")
    @subject_errors = (@subject_to_show.present? && @subj_to_proc[@subject_to_show.id][:error]) ? true : false
    @subject_errors = true if @errors.count > 0
    Rails.logger.debug("*** @subject_errors #{@subject_errors.inspect}")

    flash[:alert] = flash[:alert].present? ? flash[:alert] + @errors[:base] : @errors[:base] if @errors[:base]
    if @stage > 1 && @present_by_subject.present?
      flash[:notify] = "#{@prior_subject_name} counts: Errors - #{@count_errors}, Updates - #{@count_updates}, Adds - #{@count_adds}, Deactivates - #{@count_deactivates}"
    end
    respond_to do |format|
      Rails.logger.debug("*** @stage = #{@stage}")
      # if @stage == 1 || @any_errors
      if @stage == 1
        format.html
      elsif @stage < 10
        format.html { render :action => "lo_matching" }
      else
        format.html { render :action => "lo_matching_update" }
      end
    end

  end # upload_LO_file

  # new UI, matching process for Bulk LO Upload
  # new UI HTML post method
  def lo_matching
    authorize! :upload_lo, SubjectOutcome
    step = 0
    begin
      current_pair = nil
      @stage = 1
      @records = Array.new
      @errors = Hash.new
      # @selections = Hash.new
      @selection_params = params['selections'].present? ? params['selections'] : Hash.new
      # @selected_pairs = Hash.new
      # @selected_new_rec_ids = Array.new
      # @selected_db_ids = Array.new
      # @deactivations = Array.new
      @error_details = Hash.new
      flash[:alert] = nil

      @inactive_old_count = 0

      action_count = 0

      # get the model school
      # - creates/udpates @school, @school_year
      @school = lo_get_model_school(params)
      # get the subjects for the model school
      @subjects = Subject.where(school_id: @school.id).includes(:discipline).order('disciplines.name, subjects.name')
      # if only processing one subject
      # - creates/updates @match_subject, @subject_id, @errors[:subject]
      @match_subject = lo_get_match_subject(params)
      @process_by_subject = lo_get_processed_subject(params)

      @stage = 2
      step = 0
      Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")

      Rails.logger.debug("*** create subject hashes")
      @subject_ids = Hash.new
      @subject_names = Hash.new
      @subjects.each do |s|
        # @subject_ids[s.id] = s if !@subject_id.present? || (@subject_id.present? && @subject_id == s.id) # IDs of all subjects to process
        @subject_ids[s.id] = s if @process_by_subject.present? || (@match_subject.present? && @match_subject.id == s.id) # IDs of single or all subjects to process
        @subject_names[s.name] = s
      end

      step = 1
      Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # get records and hash of new LO records from hidden variables (params)
      Rails.logger.debug("*** lo_get_file_from_hidden")
      recs_from_hidden = lo_get_file_from_hidden(params)
      @records_clean = recs_from_hidden[:records]
      @records = @records_clean.clone
      Rails.logger.debug("*** recs from hidden returned:")
      # @records.each{|rec| Rails.logger.debug("*** rec: #{rec}")}
      # @new_recs_to_process = lo_get_new_recs_to_process(@records)
      @new_los_by_rec_clean = recs_from_hidden[:los_by_rec]
      @new_los_by_lo_code_clean = recs_from_hidden[:new_los_by_lo_code]
      # @new_los_by_rec = @new_los_by_rec_clean.clone

      @stage = 3
      step = 0
      Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # get the subject outcomes from the database for all subjects to process

      step = 1
      # get the subject outcomes from the database by subject
      saved_old_los = lo_get_all_old_los
      @old_db_ids_by_subject = saved_old_los[:old_db_ids_by_subject].clone
      @all_old_los = saved_old_los[:all_old_los].clone

      step = 2
      Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # get the subject outcomes from the upload by subject
      new_los = lo_get_all_new_los(@records)
      @new_rec_ids_by_subject = new_los[:new_rec_ids_by_subject].clone
      @all_new_los = new_los[:all_new_los].clone
      invalid_subject_names = new_los[:invalid_subject_names].clone
      @errors[:base] = append_with_comma(@errors[:base], "Invalid subject(s): #{invalid_subject_names.map {|k,v| v}.join(', ')}") if invalid_subject_names.count > 0

      step = 3
      Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # @errors = Hash.new

      step = 4
      Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # hash to determine if subject should be processed or matched (by subject id)
      @subj_to_proc = Hash.new({})

      # array of old and new records to present to the user
      @new_los_to_present = Array.new
      @old_los_to_present = Array.new
      @present_by_subject = nil
      @subject_to_show = nil

      @prior_subject = @match_subject
      @count_errors = 0
      @count_updates = 0
      @count_adds = 0
      @count_deactivates = 0
      @total_errors = params['total_errors'].present? ? (Integer(params['total_errors']) rescue 0) : 0
      @total_updates = params['total_updates'].present? ? (Integer(params['total_updates']) rescue 0) : 0
      @total_adds =  params['total_adds'].present? ? (Integer(params['total_adds']) rescue 0) : 0
      @total_deactivates = params['total_deactivates'].present? ? (Integer(params['total_deactivates']) rescue 0) : 0
      @count_updated_subjects = params['count_updated_subjects'].present? ? (Integer(params['count_updated_subjects']) rescue 0) : 0

      Rails.logger.debug("*** @count_updated_subjects #{@count_updated_subjects.inspect}")

      step = 5
      Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")

      Rails.logger.debug("*** @match_subject #{@match_subject.inspect}")

      go_to_next = false
      updates_done = false
      @action = params["submit_action"]
      if @action == "set_matches"
        Rails.logger.debug("*** Will update the database from selections for this subject #####")

        # ensure all new records have a selection parameter
        Rails.logger.debug("*** @selection_params.count: #{@selection_params.count}")
        Rails.logger.debug("*** @new_rec_ids_by_subject[@match_subject.id].count: #{@new_rec_ids_by_subject[@match_subject.id].count}")
        @errors[:base] = append_with_comma(@errors[:base], "invalid update parameter count #{@selection_params.count} != #{@new_rec_ids_by_subject[@match_subject.id].count}") if @selection_params.count != @new_rec_ids_by_subject[@match_subject.id].count

        # check for duplicate database assignments
        counts_h = Hash.new(0)
        # Rails.logger.debug("*** @selection_params: #{@selection_params.inspect}")
        @selection_params.each{ |k,v| counts_h[(Integer(v) rescue 0)] += 1}
        Rails.logger.debug("*** counts_h: #{counts_h.inspect}")
        # drop unmatched records from selection processing
        counts_h[0] = 0
        # Rails.logger.debug("*** counts_h: #{counts_h.inspect}")
        dup_recs = counts_h.select{|k,v| v>1}.keys
        Rails.logger.debug("*** dup_recs: #{dup_recs.inspect}")
        if @errors.count == 0
          @selection_params.each do |new_rec_id,old_db_id|
            new_rec_id_num = Integer(new_rec_id) rescue 0
            Rails.logger.debug("*** new_rec_id: #{new_rec_id.inspect} => #{new_rec_id_num}")
            new_rec = @all_new_los[(new_rec_id_num)]
            new_rec_error = new_rec[:error].present? ? new_rec[:error] : ''
            # Rails.logger.debug("*** new_rec: #{new_rec.inspect}")
            if old_db_id.present?
              # new record assigned to an old record

              old_db_id_num = Integer(old_db_id) rescue 0
              Rails.logger.debug("*** old_db_id: #{old_db_id.inspect} => #{old_db_id_num}")
              old_rec = @all_old_los[old_db_id_num]
              Rails.logger.debug("*** old_rec: #{old_rec.inspect}")
              new_rec_error += 'Mismatched subject' if old_rec[:subject_id] != new_rec[:subject_id]
              if dup_recs.include?(old_db_id_num)
                new_rec_error += "Duplicate Match #{old_rec[:match_id]}-#{old_rec[:lo_code]}"
                Rails.logger.debug("*** duplicate match on #{new_rec_id}/#{old_rec} -  #{old_rec[:match_id]}-#{old_rec[:lo_code]}")
              end
              if counts_h.values.max < 2
                Rails.logger.debug("*** lo_update old_rec: #{old_rec}")
                updates_done = true if lo_update(new_rec, old_rec)
              end
              new_rec[:error] = new_rec_error if new_rec_error.present?
            else # old_db_id.present?
              if counts_h.values.max < 2
                updates_done = true if lo_add(new_rec)
              end
            end # old_db_id.present?
            # Rails.logger.debug("*** new_rec: #{new_rec.inspect}")
          end # params['selections'].each
        end # @errors.count == 0

        Rails.logger.debug("*** lo_deact_rest_old_recs")
        if @count_errors == 0 && @errors.count == 0 && counts_h.values.max < 2
          updates_done = true if lo_deact_rest_old_recs(@match_subject)
        end
        Rails.logger.debug("*** lo_deact_rest_old_recs done")

        # update database records in @all_old_los
        lo_get_old_los_for_subj(@match_subject)

        if updates_done
          @count_updated_subjects += 1
          go_to_next = true
        end
      elsif @action == "save_all"
        Rails.logger.debug("*** Will update the database from selections for all subjects #####")
        @stage = 10
      elsif @action == "skip"
        Rails.logger.debug("*** Will Skip Learning Outcomes for subject: #{@match_subject.id}-#{@match_subject.name}")
        go_to_next = true
      elsif @action == "cancel"
        Rails.logger.debug("*** Will cancel update for this subject and go to report")
        @stage = 10
      end
      Rails.logger.debug("*** params[:submit_action]: #{params[:submit_action]}")

      ##### get subject to present to user #####
      Rails.logger.debug("*** get subject to present to user - @match_subject #{@match_subject.inspect}")
      Rails.logger.debug("*** @subject_to_show #{@subject_to_show.inspect}")
      do_subject_matched = false
      @subjects.each_with_index do |subj, ix|
        if subj.id == @match_subject.id
          # we found the subject just presented to the user
          Rails.logger.debug("*** matched subject just presented #{ix} - #{subj.inspect}")

          do_subject_matched = true
          next if go_to_next
        end

        Rails.logger.debug("*** subject looping #{ix} - #{subj.name}")

        if do_subject_matched
          lo_setup_subject(subj, true) # didn't do all auto updates in lo_upload
          Rails.logger.debug("*** matched next subject #{ix} - #{subj.inspect}")
        end

        break if @subject_to_show.present?
      end

      @present_by_subject = @subject_to_show
      Rails.logger.debug("*** @subject_to_show #{@subject_to_show.inspect}")
      Rails.logger.debug("*** @present_by_subject #{@present_by_subject.inspect}")
      @no_update = @subject_to_show.present? ? @subj_to_proc[@subject_to_show.id][:skip] : true
      Rails.logger.debug("*** @no_update #{@no_update.inspect}")

      Rails.logger.debug("*** Subject to Present to User: #{@subject_to_show.inspect}")

      step = 7

      Rails.logger.debug("*** Subject to Present to User: #{@subject_to_show.inspect}")

      ##### todo get next subject to present to user #####

      if @present_by_subject.present?
        step = '3a'
        Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
        # we are processing one subject, so we are not looping through subjects
        # pull the new learning outcomes to process from the @new_rec_ids_by_subject
        @new_rec_ids_by_subject[@subject_to_show.id].each do |rec_id|
          @new_los_to_present << @all_new_los[rec_id]
          # Rails.logger.debug("*** new rec to present: #{@all_new_los[rec_id]}")
        end
        step = '3b'
        Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
        # pull the old learning outcomes to process from the @old_db_ids_by_subject
        old_db_ids = @old_db_ids_by_subject[@subject_to_show.id]
        old_db_ids = [] if old_db_ids.blank?
        old_db_ids.each do |db_id|
          @old_los_to_present << @all_old_los[db_id]
          # Rails.logger.debug("*** old rec to present: #{@all_old_los[db_id]}")
        end

        lo_set_matches(@new_los_to_present, @old_los_to_present, @old_db_ids_by_subject, @all_old_los)

      else
        # all processing done, skip to report
        @stage = 10
      end


    rescue => e
      item_at = "*** lo_matching Stage: #{@stage}, step #{step} - item #{action_count+1}"
      item_at = "LO Code: #{current_pair[2][[:lo_code]]}, Action: #{current_pair[2][[:action]]}" if current_pair.present?
      msg_str = "ERROR: lo_matching Exception at #{item_at} - #{e.message}"
      @errors[:base] = append_with_comma(@errors[:base], msg_str)
      Rails.logger.error(@errors[:base])
      flash[:alert] = (@errors[:base]).truncate(100)
      @stage = 5
    end

    Rails.logger.debug("*** @total_errors: #{@total_errors.inspect} += @count_errors: #{@count_errors.inspect}")
    Rails.logger.debug("*** @total_updates: #{@total_updates.inspect} += @count_updates: #{@count_updates.inspect}")
    Rails.logger.debug("*** @total_adds: #{@total_adds.inspect} += @count_adds: #{@count_adds.inspect}")
    Rails.logger.debug("*** @total_deactivates: #{@total_deactivates.inspect} += @count_deactivates: #{@count_deactivates.inspect}")
    Rails.logger.debug("*** @count_updated_subjects #{@count_updated_subjects.inspect}")


    @prior_subject_name = @prior_subject.present? ? @prior_subject.name : ''
    @total_errors += @count_errors
    @total_updates += @count_updates
    @total_adds += @count_adds
    @total_deactivates += @count_deactivates

    Rails.logger.debug("*** @present_by_subject #{@present_by_subject.inspect}")
    @subject_errors = (@subject_to_show.present? && @subj_to_proc[@subject_to_show.id][:error]) ? true : false
    @subject_errors = true if @errors.count > 0
    Rails.logger.debug("*** @subject_errors #{@subject_errors.inspect}")

    flash[:notify] = "#{@prior_subject_name} counts: Errors - #{@count_errors}, Updates - #{@count_updates}, Adds - #{@count_adds}, Deactivates - #{@count_deactivates}"

    respond_to do |format|
      Rails.logger.debug("*** lo_matching @stage = #{@stage}")
      # if @stage == 1 || @any_errors
      if @stage < 10
        format.html
      else
        format.html { render :action => "lo_matching_update" }
      end
    end
  end

  private

end
