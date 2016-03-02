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
    authorize! :manage, :all # only system admins
    @preview = true if params['preview']
    first_display = (request.method == 'GET' && params['utf8'].blank?)
    Rails.logger.debug("*** first_display: #{first_display}")
    @stage = 1
    Rails.logger.debug("*** SchoolsController.upload_LO_file started")
    @errors = Hash.new
    @error_list = Hash.new
    @records = Array.new

    match_model_schools = School.where(acronym: 'MOD')
    if match_model_schools.count == 1
      @school = match_model_schools.first
      if @school.school_year_id.blank?
        @errors[:base] = 'ERROR: Missing school year for Model School'
      else
        @school_year = @school.school_year
        session[:school_context] = @school.id
        set_current_school
      end
    end

    if @errors.count > 0
      Rails.logger.debug("*** @errors: #{@errors.inspect}")
      # don't process, error
    elsif params['file'].blank?
      if !first_display
        @errors[:filename] = "Error: Missing Curriculum (LOs) Upload File."
      end
    else

      # stage 2
      @stage = 2
      Rails.logger.debug("*** Stage: #{@stage}")
      @subject_ids = Hash.new
      @subject_names = Hash.new
      @subjects = Subject.where(school_id: @school.id)
      @subjects.each do |s|
        @subject_ids[s.id] = s
        @subject_names[s.name] = s
      end
      # no initial errors, process file
      @filename = params['file'].original_filename
      # @errors[:filename] = 'Choose file again to rerun'
      # note: 'headers: true' uses column header as the key for the name (and hash key)
      ix = 0
      CSV.foreach(params['file'].path, headers: true) do |row|
        rhash = validate_csv_fields(row.to_hash.with_indifferent_access, @subject_names)
        rhash[COL_REC_ID] = ix
        if rhash[COL_ERROR]
          @errors[:base] = 'Errors exist - see below:' if !rhash[COL_EMPTY]
        end
        @records << rhash if !rhash[COL_EMPTY]
        ix += 1
      end  # end CSV.foreach

      # check for file duplicate LO Codes
      dup_lo_code_checked = validate_dup_lo_codes(@records)
      @error_list = dup_lo_code_checked[:error_list]
      Rails.logger.debug("*** @error_list: #{@error_list.inspect}")
      @records = dup_lo_code_checked[:records]
      Rails.logger.debug("*** records count: #{@records.count}")
      @errors[:base] = 'Errors exist - see below!!!:' if dup_lo_code_checked[:abort] || @error_list.length > 0

      # check for file duplicate LO Descriptions
      dup_lo_descs_checked = validate_dup_lo_descs(@records)
      @error_list2 = dup_lo_descs_checked[:error_list]
      Rails.logger.debug("*** @error_list2: #{@error_list2.inspect}")
      @records = dup_lo_descs_checked[:records]
      Rails.logger.debug("*** records count: #{@records.count}")
      @errors[:base] = 'Errors exist - see below!!!:' if dup_lo_descs_checked[:abort] || @error_list2.length > 0

      # validate records

      # stage 3
      @stage = 3
      Rails.logger.debug("*** Stage: #{@stage}")


      # create an hash by lo_codes for matching database to upload file.
      new_lo_codes_h = Hash.new
      new_lo_names_h = Hash.new
      @records.each_with_index do |rx, ix|
        rec  = Hash.new
        rec[COL_REC_ID] = rx[COL_REC_ID]
        rec[COL_COURSE] = rx[COL_COURSE]
        rec[COL_GRADE] = rx[COL_GRADE]
        rec[COL_MP_BITMAP] = rx[COL_MP_BITMAP]
        rec[COL_OUTCOME_CODE] = rx[COL_OUTCOME_CODE]
        rec[COL_OUTCOME_NAME] = rx[COL_OUTCOME_NAME]
        rec[PARAM_ID] = rx[PARAM_ID]
        rec[PARAM_ACTION] =  rx[PARAM_ACTION]

        shortened_name = (rx[COL_OUTCOME_NAME].present? ? rx[COL_OUTCOME_NAME].truncate(50, omission: '...') : '')
        rx[COL_SHORTENED_NAME] = shortened_name
        # new_lo_codes_by_lo << { lo_code: rx[COL_OUTCOME_CODE], ix: ix }
        # new_lo_codes_by_name << { name: shortened_name, ix: ix }
        new_lo_codes_h[rx[COL_OUTCOME_CODE]] = rec
        # Rails.logger.debug("*** new_lo_codes[#{rx[COL_OUTCOME_CODE]}] = #{rx[COL_REC_ID]}")
        new_lo_names_h[shortened_name] = rec
      end

      old_los_by_lo = Hash.new
      # optimize active record for one db call
      db_active = 0
      db_deact = 0
      SubjectOutcome.where(subject_id: @subject_ids.map{|k,v| k}).each do |so|
        subject_name = @subject_ids[so.subject_id].name
        old_los_by_lo[so.lo_code] = {
          db_id: so.id,
          subject_name: subject_name,
          subject_id: so.subject_id,
          lo_code: so.lo_code,
          name: so.name,
          short_desc: so.shortened_description,
          desc: so.description,
          grade: so.subject.grade_from_subject_name,
          mp: SubjectOutcome.get_bitmask_string(so.marking_period),
          active: so.active
        }
        if so.active
          db_active += 1
        else
          db_deact += 1
        end
      end

      @records3 = Array.new

      # process matches
      # new_lo_codes.product(old_lo_codes).each.map { |p| p if }
      # process matches
      @mismatch_count = 0
      @not_add_count = 0 # temporary coding to allow add only mode till programming completed.
      iy = 0
      white = Text::WhiteSimilarity.new
      old_los_by_lo.each do |rk, old_rec|
        new_match = new_lo_codes_h[rk]
        # Rails.logger.debug("*** rk: #{rk}, new_match: #{new_match.inspect}")
        old_rec, new_match, matches = lo_match_old_new(old_rec, (new_match ||= {}))
        @records3 << [old_rec, new_match, matches] # output matches for matching report
        # Rails.logger.debug("*** new_match[COL_REC_ID] #{new_match[COL_REC_ID]}")
        @records[new_match[COL_REC_ID]][COL_STATE] = 'match_lo_code' if new_match[COL_REC_ID]
        # Rails.logger.debug("*** ro: #{old_rec.inspect}")
        # Rails.logger.debug("*** rn: #{new_match.inspect}")
        # Rails.logger.debug("*** matches: #{matches.inspect}")

        # determine if all actions have been determined (no mismatch actions)
        @mismatch_count += 1 if old_rec[PARAM_ACTION] == 'Mismatch' || (new_match && new_match[PARAM_ACTION] == 'Mismatch')

        # determine if any action other than Add has been used (Add only till programming done)
        @not_add_count += 1 if !['', 'Add'].include?(old_rec[PARAM_ACTION])

      end

      # output any unmatched new records
      @records.each_with_index do |rx, ix|
        if rx[COL_STATE].blank?
          # Rails.logger.debug("*** @record: #{rx.inspect}")
          old_rec, rx, matches = lo_match_old_new({}, rx)
          @records3 << [old_rec, rx, matches] # output matches for matching report
          @mismatch_count += 1 if rx[PARAM_ACTION] == 'Mismatch'

          # determine if any action other than Add has been used (Add only till programming done)
          @not_add_count += 1 if !['', 'Add'].include?(rx[PARAM_ACTION])
        end
      end

      Rails.logger.debug("***xxx records count: #{@records.count}")
      Rails.logger.debug("***xxx records3 count: #{@records3.count}")
      Rails.logger.debug("***xxx mismatch_count : #{@mismatch_count}")
      Rails.logger.debug("***xxx not_add_count : #{@not_add_count}")
      Rails.logger.debug("***xxx db_active count: #{db_active}")
      Rails.logger.debug("***xxx db_deact count: #{db_deact}")

    end # end stage 1-4

    if @errors.count == 0 && @error_list.length == 0 && !first_display

      # stage 5
      @stage = 5
    end

    Rails.logger.debug("*** Final Stage: #{@stage}")

    Rails.logger.debug("*** @errors: #{@errors.inspect}")
    @any_errors = @errors.count > 0 || @error_list.count > 0

    @rollback = false

    respond_to do |format|
      if @stage == 1 || @any_errors
        format.html
      else
        format.html { render :action => "lo_matching" }
      end
    end

  end # upload_LO_file

  # new UI, matching process for Bulk LO Upload
  # new UI HTML post method
  def lo_matching
    authorize! :manage, :all # only system admins
    Rails.logger.debug("*** SchoolsController.lo_matching started")
    begin
      step = 0
      records = Array.new
      @records3 = Array.new
      @errors = Hash.new
      @subject_ids = Hash.new

      @school = School.find(params['school_id'])
      raise('Invalid school - not model school') if @school.acronym != 'MOD'

      Subject.where(school_id: @school.id).each do |s|
        @subject_ids[s.id] = s
      end

      step = 1
      old_los_by_lo = Hash.new
      # optimize active record for one db call
      # SubjectOutcome.where(subject_id: @subject_ids.map{|k,v| k}).each do |so|
      SubjectOutcome.where(subject_id: Subject.where(school_id: @school.id).pluck(:id)).each do |so|
        subject_name = @subject_ids[so.subject_id].name
        old_los_by_lo[so.lo_code] = {db_id: so.id, subject_name: subject_name, subject_id: so.subject_id, lo_code: so.lo_code, name: so.name, short_desc: so.shortened_description, desc: so.description, grade: so.subject.grade_from_subject_name, mp: SubjectOutcome.get_bitmask_string(so.marking_period), active: so.active }
      end

      step = 2
      @mismatch_count = 0
      @not_add_count = 0 # temporary coding to allow add only mode till programming completed.
      old_rec_actions = []
      params['pair'].each do |p|
        pold = p[1]['o']
        pold ||= {}
        pnew = p[1]['n']
        pnew ||= {}

        # recreate upload records (with only fields needed)
        if pnew.length > 0 && pnew[COL_REC_ID]
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
          records << rec
        end

        # save off old rec if there is an action to do on it
        if pold.length > 0 && pold[PARAM_ACTION] && !['Mismatch', ''].include?(pold[PARAM_ACTION])
          old_rec_actions << pold
        end

        # determine if all actions have been determined (no mismatch actions)
        if pold[PARAM_ACTION] == 'Mismatch' || pnew[PARAM_ACTION] == 'Mismatch'
          @mismatch_count += 1
        end

        # determine if any action other than Add has been used (Add only till programming done)
        @not_add_count += 1 if !['', 'Add'].include?(pold[PARAM_ACTION]) || !['', 'Add'].include?(pnew[PARAM_ACTION])

      end

      step = 3
      new_lo_codes_h = Hash.new
      new_lo_names_h = Hash.new
      records.each do |rx|
        shortened_name = (rx[COL_OUTCOME_NAME].present? ? rx[COL_OUTCOME_NAME].truncate(50, omission: '...') : '')
        new_lo_codes_h[rx[COL_OUTCOME_CODE]] = rx
        new_lo_names_h[shortened_name] = rx
      end

      # Rails.logger.debug("*** new_lo_codes_h: #{new_lo_codes_h.inspect}")
      # Rails.logger.debug("*** new_lo_names_h: #{new_lo_names_h.inspect}")
      step = 4
      # process matches
      iy = 0
      white = Text::WhiteSimilarity.new
      old_los_by_lo.each do |rk, old_rec|
        new_match = new_lo_codes_h[rk]
        old_rec, new_match, matches = lo_match_old_new(old_rec, (new_match ||= {}))
        @records3 << [old_rec, new_match, matches] # output matches for matching report
        # Rails.logger.debug("*** ro: #{old_rec.inspect}")
        # Rails.logger.debug("*** rn: #{new_match.inspect}")
        # Rails.logger.debug("*** matches: #{matches.inspect}")
      end

      step = 5
      action_count = 0
      @records4 = []
      if @mismatch_count == 0 && params[:submit_action] == 'save_all'
        ActiveRecord::Base.transaction do
          old_rec_actions.each do |rec|
            # Rails.logger.debug("*** old rec: #{rec}")
            case rec[PARAM_ACTION]
            when 'Remove'
              so = SubjectOutcome.find(rec[COL_REC_ID])
              so.active = false
              so.save!
              action_count += 1
              action = 'Removed'
              @records4 << [so, 'Removed']
            when 'Restore'
              so = SubjectOutcome.find(rec[COL_REC_ID])
              so.active = true
              so.save!
              action_count += 1
              action = 'Restored'
              @records4 << [so, 'Restored']
            when ''
              # ignore
              # Rails.logger.debug("*** 'ignore' action")
            when 'Mismatch'
              raise("Attempt to update with Mismatch - item #{action_count+1}")
            else
              raise("Invalid subject outcome action - item #{action_count+1}")
            end

          end
          records.each do |rec|
            # Rails.logger.debug("*** new rec: #{rec}")
            case rec[PARAM_ACTION]
            when 'Add'
              so = SubjectOutcome.new
              so.lo_code = rec[COL_OUTCOME_CODE]
              so.description = rec[COL_OUTCOME_NAME]
              so.subject_id = rec[COL_COURSE_ID].to_i
              so.marking_period = rec[COL_MP_BITMAP]
              so.save!
              action_count += 1
              action = 'Added'
              @records4 << [so, 'Added']
            when ''
              # ignore
              # Rails.logger.debug("*** 'ignore' action")
            when 'Mismatch'
              raise("Attempt to update with Mismatch - item #{action_count+1}")
            else
              raise("Invalid subject outcome action - item #{action_count+1}")
            end

          end
          # raise "Successful Test cancelled" if action_count > 0
        end # transaction
      else
        @errors[:base] =  'Invalid Upload (only adds allowed) - Not Saved'
      end # if update

    rescue => e
      msg_str = "ERROR: lo_matching Exception at step #{step} - #{e.message}"
      @errors[:base] = append_with_comma(@errors[:base], msg_str)
      Rails.logger.error(msg_str)
      flash.now[:alert] = msg_str
    end

    respond_to do |format|
      if step == 5 && @errors.count == 0
        format.html { render :action => "lo_matching_update" }
      else
        if @errors.count > 0
          flash[:alert] = (@errors[:base].present?) ? @errors[:base] : 'Errors'
        end
        format.html
      end
    end

  end


  # def lo_matching_update
  # this page is rendered from lo_matching action
  # end

  private

end
