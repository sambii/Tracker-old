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
      @errors[:base] = 'Errors exist - see below!!!:' if dup_lo_code_checked[:abort] || @error_list.length > 0


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

      step = 3
      Rails.logger.debug("*** Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # @errors = Hash.new

      step = 4
      Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # hash to determine if subject should be processed or matched (by subject id)
      @subj_to_proc = Hash.new({})


      @prior_subject = nil
      @count_errors = 0
      @count_updates = 0
      @count_adds = 0
      @count_deactivates = 0

      Rails.logger.debug("*** @match_subject #{@match_subject.inspect}")
      # get starting subject to present to user
      if @match_subject.present?
        lo_setup_subject(@match_subject, false)
        @subject_to_show = @match_subject # always show match subject if subject has been chosen
      else
        @subjects.each do |subj|
          lo_setup_subject(subj, true)
        end
        @present_by_subject = @subject_to_show
      end
      Rails.logger.debug("*** @subject_to_show #{@subject_to_show.inspect}")
      Rails.logger.debug("*** @present_by_subject #{@present_by_subject.inspect}")
      @no_update = @subject_to_show.present? ? @subj_to_proc[@subject_to_show.id][:skip] : true
      Rails.logger.debug("*** @no_update #{@no_update.inspect}")
      Rails.logger.debug("*** @allow_save_all #{@allow_save_all}")
      Rails.logger.debug("*** @errors.count #{@errors.count}")

      Rails.logger.debug("*** Subject to Present to User: #{@subject_to_show.inspect}")
      if @subject_to_show.present?
        step = '3a'
        Rails.logger.debug("*** Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
        # we are processing one subject, so we are not looping through subjects
        # pull the new learning outcomes to process from the @new_rec_ids_by_subject
        @new_rec_ids_by_subject[@subject_to_show.id].each do |rec_id|
          @new_los_to_present << @all_new_los[rec_id]
        end
        step = '3b'
        Rails.logger.debug("*** Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
        # pull the old learning outcomes to process from the @old_db_ids_by_subject
        @old_db_ids_by_subject[@subject_to_show.id].each do |db_id|
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
        msg_str = "ERROR: lo_matching Exception at @stage: #{@stage}, step #{step}, item #{action_count+1} - #{e.message}"
        @errors[:base] = append_with_comma(@errors[:base], msg_str)
        Rails.logger.error(msg_str)
        flash[:alert] = msg_str
        @stage = 5
      end
    end

    @total_errors = @count_errors
    @total_updates = @count_updates
    @total_adds = @count_adds
    @total_deactivates = @count_deactivates

    @old_los_to_present.each{|rec| Rails.logger.debug("*** present old rec: #{rec}")}
    @new_los_to_present.each{|rec| Rails.logger.debug("*** present new rec: #{rec}")}

    flash[:alert] = flash[:alert].present? ? flash[:alert] + @errors[:base] : @errors[:base] if @errors[:base]
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
      # @selection_params = Hash.new
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
      @records.each{|rec| Rails.logger.debug("*** rec: #{rec}")}
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

      step = 5
      Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")

      Rails.logger.debug("*** @match_subject #{@match_subject.inspect}")

      go_to_next = false
      @action = params["submit_action"]
      if @action == "set_matches"
        Rails.logger.debug("*** Will update the database from selections for this subject #####")
        Rails.logger.debug("*** @all_old_los: #{@all_old_los.inspect}")
        params['selections'].each do |new_rec_id,old_db_id|
          new_rec_id_num = Integer(new_rec_id) rescue 0
          Rails.logger.debug("*** new_rec_id: #{new_rec_id.inspect} => #{new_rec_id_num}")
          new_rec = @all_new_los[(new_rec_id_num)]
          Rails.logger.debug("*** new_rec: #{new_rec.inspect}")
          if old_db_id.present?
            # new record assigned to an old record
            old_db_id_num = Integer(old_db_id) rescue 0
            Rails.logger.debug("*** old_db_id: #{old_db_id.inspect} => #{old_db_id_num}")
            old_rec = @all_old_los[old_db_id_num]
            Rails.logger.debug("*** old_rec: #{old_rec.inspect}")
            new_rec[:error] = new_rec[:error].present? ? new_rec[:error] + 'Mismatched subject' : 'Mismatched subject' if old_rec[:subject_id] != new_rec[:subject_id]
            Rails.logger.debug("*** lo_update old_rec: #{old_rec}")
            lo_update(new_rec, old_rec)
          else # old_db_id.present?
            lo_add(new_rec)
          end # old_db_id.present?
        end # params['selections'].each

        Rails.logger.debug("*** lo_deact_rest_old_recs")
        lo_deact_rest_old_recs(@match_subject) if @count_errors == 0
        Rails.logger.debug("*** lo_deact_rest_old_recs done")

        # update database records in @all_old_los
        lo_get_old_los_for_subj(@match_subject)

        go_to_next = true
      elsif @action == "save_all"
        Rails.logger.debug("*** Will update the database from selections for all subjects #####")
        @stage = 10
      elsif @action == "skip"
        Rails.logger.debug("*** Will Skip Learning Outcomes for subject: #{@match_subject}")
        go_to_next = true
      elsif @action == "cancel"
        Rails.logger.debug("*** Will cancel update for this subject and go to report")
        @stage = 10
      end
      Rails.logger.debug("*** params[:submit_action]: #{params[:submit_action]}")

      if go_to_next
        ##### get next subject to present to user #####
        Rails.logger.debug("*** @match_subject #{@match_subject.inspect}")
        do_subject_setup = false
        @subjects.each do |subj|
          if subj.id == @match_subject.id
            # we found the last subject processed in the subjects array
            # set up the rest of the subjects
            do_subject_setup = true
            next
          end

          if do_subject_setup
            lo_setup_subject(subj, true)
          end
        end
        @present_by_subject = @subject_to_show
        Rails.logger.debug("*** @subject_to_show #{@subject_to_show.inspect}")
        Rails.logger.debug("*** @present_by_subject #{@present_by_subject.inspect}")
        @no_update = @subject_to_show.present? ? @subj_to_proc[@subject_to_show.id][:skip] : true
        Rails.logger.debug("*** @no_update #{@no_update.inspect}")

        Rails.logger.debug("*** Subject to Present to User: #{@subject_to_show.inspect}")
      end



      step = 7
      Rails.logger.debug("*** lo_matching Stage: #{@stage}, step: #{step}, @allow_save: #{@allow_save}, @action == 'skip': #{@action == 'skip'}")

    rescue => e
      item_at = "*** lo_matching Stage: #{@stage}, step #{step} - item #{action_count+1}"
      item_at = "LO Code: #{current_pair[2][[:lo_code]]}, Action: #{current_pair[2][[:action]]}" if current_pair.present?
      msg_str = "ERROR: lo_matching Exception at #{item_at} - #{e.message}"
      @errors[:base] = append_with_comma(@errors[:base], msg_str)
      Rails.logger.error(msg_str)
      flash[:alert] = msg_str
      @stage = 5
    end

    step = 8

    Rails.logger.debug("*** Subject to Present to User: #{@subject_to_show.inspect}")

    ##### todo get next subject to present to user #####

    if @present_by_subject.present?
      step = '3a'
      Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # we are processing one subject, so we are not looping through subjects
      # pull the new learning outcomes to process from the @new_rec_ids_by_subject
      @new_rec_ids_by_subject[@subject_to_show.id].each do |rec_id|
        @new_los_to_present << @all_new_los[rec_id]
      end
      step = '3b'
      Rails.logger.debug("*** lo_matching Stage: #{@stage}, Step #{step} Time @ #{Time.now.strftime("%d/%m/%Y %H:%M:%S")}")
      # pull the old learning outcomes to process from the @old_db_ids_by_subject
      @old_db_ids_by_subject[@subject_to_show.id].each do |db_id|
        @old_los_to_present << @all_old_los[db_id]
      end

      lo_set_matches(@new_los_to_present, @old_los_to_present, @old_db_ids_by_subject, @all_old_los)

    else
      # all processing done, skip to report
      @stage = 10
    end

    Rails.logger.debug("*** @total_errors: #{@total_errors.inspect} += @count_errors: #{@count_errors.inspect}")
    Rails.logger.debug("*** @total_updates: #{@total_updates.inspect} += @count_updates: #{@count_updates.inspect}")
    Rails.logger.debug("*** @total_adds: #{@total_adds.inspect} += @count_adds: #{@count_adds.inspect}")
    Rails.logger.debug("*** @total_deactivates: #{@total_deactivates.inspect} += @count_deactivates: #{@count_deactivates.inspect}")
    @total_errors += @count_errors
    @total_updates += @count_updates
    @total_adds += @count_adds
    @total_deactivates += @count_deactivates

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
