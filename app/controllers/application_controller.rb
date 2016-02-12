# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class ApplicationController < ActionController::Base
  protect_from_forgery
  around_filter :hide_student_names,    if:     :current_researcher
  before_filter :get_referrer,          except: [:create, :update]
  before_filter :cache_buster,          only:   [:new, :edit, :rate]
  before_filter :get_flash_from_params
  before_filter :set_current_school
  before_filter :set_current_role
  before_filter :toolkit_instances

  # removed this, as it interferes with debugging
  # # prepend_before_filter :set_school,    if:     :enforce_context?
  # around_filter :profile               if Rails.env == 'development'

  #Load all service files
  Dir[Rails.root.join("app/services/**/*.rb")].each {|f| require f}

  # Require all application exception files
  Dir[Rails.root.join("app/exceptions/**/*.rb")].each {|f| require f}

  # determine layout depending upon login status
  layout :determine_layout

  # By default, the CanCan authorization gem will display a 500 error to users. This rescue_from
  # block will instead redirect users to their user dashboard with an exception message.
  rescue_from CanCan::AccessDenied do |exception|
    if user_signed_in?
      # show the user the exception message
      msg = exception.message
    else
      # no user, session has timed out or action is unauthorized
      msg = I18n.translate('errors.timeout_or_unauthorized')
    end
    if current_user
      Rails.logger.error("ERROR: User #{current_user.id} got #{I18n.translate('errors.unauthorized')} with referrer: #{request.referrer}, original_url: #{request.original_url}")
    else
      Rails.logger.error("ERROR: got #{I18n.translate('errors.timeout_or_unauthorized')}")
    end
    redirect_to root_path, :alert => msg
  end

  # override the devise after signin redirect
  def after_sign_in_path_for(resource)
    # save off the last HTML page displayed and clear it
    if current_user.temporary_password.nil?
      # bring the user to their dashboard page
      user_path(current_user)
    else
      # user is currently using a temporary password, force them to change it
    Rails.logger.info("INFO: Initial Change Password for #{current_user.id}")
      change_password_user_path(current_user)
    end
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, session)
  end

  def current_school_id
    if current_user.blank?
      school_id = 0
    elsif current_user.system_administrator? || current_user.researcher?
      school_id = session[:school_context] ? session[:school_context].to_i : 0
    else
      school_id = current_user.school_id ? current_user.school_id : 0
    end
    return school_id
  end

  def get_current_school
    begin
      school = School.find(current_school_id)
    rescue => e
      school = School.new
    end
  end

  protected

  def set_current_school
    if current_user
      set_school if enforce_context?
      cur_schid = current_school_id
      if @current_school && @current_school.id == cur_schid
        @current_school
      else
        begin
          @current_school = School.find(cur_schid)
        rescue => e
          @current_school = School.new
        end
      end
      @current_school
    end
  end

  def set_current_role
    @current_role == ''
    if current_user
      if current_user.staff?

        # get current role from session variable
        current_role = session[:current_role] if ['system_administrator', 'researcher', 'school_administrator', 'teacher', 'counselor', 'student', 'parent'].include?(session[:current_role])
        Rails.logger.debug("read session[:current_role]: #{session[:current_role]}")
        Rails.logger.debug("current_role: #{current_role}")

        # ensure user has that role (else assign the first role to them)
        if !current_role.nil? && current_user.role_symbols.include?(current_role.to_sym)
          @current_role = current_role
        else
          @current_role = current_user.role_symbols.first
        end

        # update current role from query string if valid and user has that role
        if params[:role]
          if ['system_administrator', 'researcher', 'school_administrator', 'teacher', 'counselor', 'student', 'parent', ''].include?(params[:role])
            new_role = params[:role]
            if current_user.role_symbols.include? (new_role.to_sym)
              @current_role = new_role
            end
          end
        end
        session[:current_role] = @current_role
        Rails.logger.debug("set session[:current_role] to #{session[:current_role]}")
      else
        @current_role = 'parent' if current_user.parent?
        @current_role = 'student' if current_user.student?
      end
    else
      # Rails.logger.error("ERROR -  Cannot set_current_role, user is not logged in **")
    end
  end

  def toolkit_instances
    # trackers (section pages) are overridden by user type.  They are defaulted here to ensure they exist.
    @toolkit_current_sections = []
    @toolkit_past_sections = []
    @toolkit_subjects = []
    load_subjects = false
    load_sections = false
    user_loaded = 'User'.constantize
    Rails.logger.debug ("*** @current_school_id = #{@current_school_id}")
    if current_user.present?
      # admins and researchers get to list subjects since they normally do not have assigned sections
      if current_user.system_administrator? || current_user.school_administrator? || current_user.researcher?
        load_subjects = true
        Rails.logger.debug("*** load subjects")
      end
      #  see if user with @current_role has assigned sections.
      clazz = @current_role.to_s.camelize.constantize
      user_loaded = clazz.find(current_user.id)
      if user_loaded && user_loaded.methods.include?(:sections)
        load_sections = true
      elsif user_loaded.parent?
        load_sections = true
      end
    end

    # list of current and past section ids for keeping toolkit item open for current and past trackers
    @toolkit_current_enrollments = []
    @toolkit_past_enrollments = []
    @toolkit_current_section_ids = []
    @toolkit_past_section_ids = []
    if load_subjects
      Rails.logger.debug("*** load_subjects - @current_school = #{@current_school.inspect.to_s}")
      @toolkit_subjects = Subject.where(school_id: @current_school.id).order('subjects.name')
    end
    if load_sections
      Rails.logger.debug("*** load users sections")
      if current_user.student? && user_loaded.methods.include?(:enrollments)
        @toolkit_current_enrollments = user_loaded.enrollments.order(:position).current
        @toolkit_past_enrollments = user_loaded.enrollments.order(:position).old
      elsif current_user.parent? && user_loaded.methods.include?(:child)
        @toolkit_current_enrollments = user_loaded.child.enrollments.order(:position).current
        @toolkit_past_enrollments = user_loaded.child.enrollments.order(:position).old
      end
      if user_loaded.staff? && user_loaded.methods.include?(:sections)
        @toolkit_current_sections = user_loaded.sections.order(:position).current.all
        @toolkit_current_section_ids = @toolkit_current_sections.map(&:id)
        @toolkit_past_sections = user_loaded.sections.order(:position).old.all
        @toolkit_past_section_ids = @toolkit_past_sections.map(&:id)
      end
    end

    @current_school = get_current_school

    Rails.logger.debug("*** toolkit_instances initialized with #{@toolkit_current_sections.count} & #{@toolkit_past_sections.count} & #{@toolkit_subjects.count}")

    # remember if toolkit is shown or hidden (from session variable)
    @show_toolkit = 'true'
    @show_toolkit = session[:toolkit] if ['true', 'false'].include?(session[:toolkit])
    Rails.logger.debug("*** @show_toolkit = #{@show_toolkit}")

    # remember tracker page cell size (from session variable)
    @cell_size = 'regular-mode'
    match_values = ['thinner-mode', 'thin-mode', 'regular-mode', 'wide-mode', 'wider-mode']
    @cell_size = session[:cell_size] if match_values.include?(session[:cell_size])
    Rails.logger.debug("*** @cell_size = #{@cell_size}")
  end


    # Ideally, this will "force" browsers to request the page from the web server each time the
    # user loads the page, rather than loading an old version with outdated information.
    def cache_buster
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end

    def current_researcher
      if current_user.try(:researcher) # Uses "try" in case current_user is nil!
        return true
      end
      false
    end

    # These two methods work together to set the school name for displaying the school context if it has
    # been established for a system administrator or Researcher
    def enforce_context?
      if current_user.present?
        if (current_user.system_administrator? || current_user.researcher?) &&
            session[:school_context].to_i > 0
          return true
        end
      end
      false
    end

    def set_school
      Rails.logger.debug("*** SCHOOL from session: #{session[:school_context]}")
      begin
        @school_name ||= School.find(session[:school_context]).name
      rescue
        # fix for database changed, so last school context is invalid for system admin
        if current_user.system_administrator?
          session[:school_context] = '0'
          @school_name = 'No School Context'
        end
      end
    end

    # This before_filter is called on all controller actions except on create and update actions
    # (since they generally redirect). It keeps track of where to send the users back to if the
    # application has need (i.e. send the user back to the page from which they decided to fill
    # a form.)
    def get_referrer
      # todo -  make sure we only save gets and HTML calls by:
      # making sure the request.method == 'GET' && request.format.to_s.slice(-4,4).upcase == 'HTML'
      referrer = request.referrer
      orig_url = request.original_url
      orig_path = request.env['PATH_INFO']
      Rails.logger.debug("*** request.referrer: #{referrer}")
      Rails.logger.debug("*** request.original_url: #{orig_url}")
      Rails.logger.debug("*** request.method == GET?: #{request.method}")
      Rails.logger.debug("*** request.format == HTML?: #{request.format.to_s}")
      Rails.logger.debug("*** session[:return_to]: #{session[:return_to].inspect.to_s}")
      Rails.logger.debug("*** session[:close_to_path]: #{session[:close_to_path]}")
      Rails.logger.debug("*** session[:school_context]: #{session[:school_context]}")
      Rails.logger.debug("*** session[:this_original_url]: #{session[:this_original_url].inspect.to_s}")
      Rails.logger.debug("*** session[:last_original_url]: #{session[:last_original_url].inspect.to_s}")
      route_path = (request.method == 'GET') ? Rails.application.routes.recognize_path( orig_url, :method => :get ) : Hash.new
      Rails.logger.debug("*** route_path : #{route_path.inspect.to_s}")
      # create last_original_url to be last page viewed by user for last page link next to breadcrumbs
      update_url = true
      update_url = false if orig_url.blank?
      update_url = false if orig_path.blank?
      update_url = false if orig_path == '/'
      update_url = false if orig_path == '/users/sign_out'
      type_of_users = %w(users system_administrators school_administrators teacher students parents counselors researchers)
      update_url = false if (route_path[:action] == 'show' && type_of_users.include?(route_path[:controller]) && !current_user.nil? && route_path[:id] == current_user.id.to_s )
      update_url = false if request.format != 'text/html'
      update_url = false if session[:this_original_url] == orig_url # dont update if same
      Rails.logger.debug("*** update_url: #{update_url}")
      if session[:last_original_url].nil?
        session[:last_original_url] = referrer
        session[:this_original_url] = referrer
      end
      if update_url
        session[:last_original_url] = session[:this_original_url]
        session[:this_original_url] = orig_url
      end
      Rails.logger.debug("*** UPDATED session[:last_original_url]: #{session[:last_original_url]}")
      session[:return_to] = request.referrer
      session[:return_to] ||= root_url
      # todo - compare and see if return_to and update_url can be merged.

    end

    # keep session info after logout for use in home controller
    def after_sign_out_path_for(resource_or_scope)
      # request.referrer
      root_path
    end

    def hide_student_names &block
      begin
        Student.send(:define_method, :first_name) do
          SecureRandom.hex(3)
        end
        Student.send(:define_method, :last_name) do
          SecureRandom.hex(5)
        end
        Student.send(:define_method, :username) do
          SecureRandom.hex(5)
        end
        Student.send(:define_method, :street_address) do
          SecureRandom.hex(6)
        end
        Student.send(:define_method, :city) do
          SecureRandom.hex(5)
        end
        Student.send(:define_method, :state) do
          SecureRandom.hex(4)
        end
        Student.send(:define_method, :zip_code) do
          SecureRandom.hex(3)
        end
        Student.send(:define_method, :phone) do
          SecureRandom.hex(4)
        end
        Parent.send(:define_method, :first_name) do
          SecureRandom.hex(3)
        end
        Parent.send(:define_method, :last_name) do
          SecureRandom.hex(5)
        end
        Parent.send(:define_method, :username) do
          SecureRandom.hex(5)
        end
        Parent.send(:define_method, :street_address) do
          SecureRandom.hex(6)
        end
        Parent.send(:define_method, :city) do
          SecureRandom.hex(5)
        end
        Parent.send(:define_method, :state) do
          SecureRandom.hex(4)
        end
        Parent.send(:define_method, :zip_code) do
          SecureRandom.hex(3)
        end
        Parent.send(:define_method, :phone) do
          SecureRandom.hex(4)
        end
        yield
      ensure
        Student.send(:define_method, :first_name) do
          read_attribute(:first_name)
        end
        Student.send(:define_method, :last_name) do
          read_attribute(:last_name)
        end
        Student.send(:define_method, :username) do
          read_attribute(:username)
        end
        Student.send(:define_method, :street_address) do
          read_attribute(:street_address)
        end
        Student.send(:define_method, :city) do
          read_attribute(:city)
        end
        Student.send(:define_method, :state) do
          read_attribute(:state)
        end
        Student.send(:define_method, :zip_code) do
          read_attribute(:zip_code)
        end
        Student.send(:define_method, :phone) do
          read_attribute(:phone)
        end
        Parent.send(:define_method, :first_name) do
          read_attribute(:first_name)
        end
        Parent.send(:define_method, :last_name) do
          read_attribute(:last_name)
        end
        Parent.send(:define_method, :username) do
          read_attribute(:username)
        end
        Parent.send(:define_method, :street_address) do
          read_attribute(:street_address)
        end
        Parent.send(:define_method, :city) do
          read_attribute(:city)
        end
        Parent.send(:define_method, :state) do
          read_attribute(:state)
        end
        Parent.send(:define_method, :zip_code) do
          read_attribute(:zip_code)
        end
        Parent.send(:define_method, :phone) do
          read_attribute(:phone)
        end
      end
    end

  def valid_current_school
    # confirm that user has a school assigned
    if current_user.blank? || current_school_id == 0
      alert_bad_school # alert the user, and send them to the school select page
      return false
    else
      # check to ensure school_id param (if passed) is for current school
      # add '= hidden_field_tag "school_id", @school.id.to_s' to top level form that need school_id param checked.
      sch_id = params[:school_id] # only checking top level form's param (use mass-assignment protection for others)
      if sch_id && sch_id != current_school_id.to_s
        alert_bad_school (sch_id)
        return false
      else
        return true
      end
    end
  end

  def alert_bad_school (school_id = nil)
    if current_user.blank?
      redirect_to root_url, :alert => I18n.translate('devise.failure.timeout')
    elsif current_user.can_change_school?
      flash[:alert] = (school_id.blank?) ?
        I18n.translate('errors.invalid_school_pick_one') :
        I18n.translate( 'errors.invalid_school_id_pick_one', id: school_id )
      redirect_to schools_url
    else
      flash[:alert] = (school_id.blank?) ?
        I18n.translate('errors.invalid_school') :
        I18n.translate( 'errors.invalid_school_id', id: school_id )
      redirect_to root_url, status: 500   # system error, user should have had a school_id set
    end
  end

  def profile
    # added begin rescue on Exception, so exceptions displayed.  Now not called anymore.
    begin
      if params[:profile] && result = RubyProf.profile { yield }

        out = StringIO.new
        RubyProf::GraphHtmlPrinter.new(result).print out, :min_percent => 0
        self.response_body = out.string
      else
        yield
      end
    rescue Exception => e
      Rails.logger.error("WARNING in application_controller.profile: Exception #{e.message}")
    end

  end

  # pass flash messages after multiple redirects after .ajaxError
  def get_flash_from_params
    # detect if access denied from ajax flash alert (from 401 unauthorized), and log it
    if params[:unauthorized_alert]
      cur_user_id = current_user.blank? ? 0 : current_user.id
      if cur_user_id != 0
        Rails.logger.error("ERROR: User ID #{cur_user_id} got Access Denied Error: #{params[:timeout_flash_alert]}")
        flash[:alert] = params[:unauthorized_alert]
      else
        flash[:alert] = params[:unauthorized_alert]
      end
    end
    flash[:alert] = params[:flash_alert] if params[:flash_alert]
    flash[:notify] = params[:flash_notify] if params[:flash_notify]
  end

  def authorize_current_user
    authorize! :read, current_user
  end

  def get_server_config
    # return ServerConfig first record (should be only one)
    begin
      @server_config ||= ServerConfig.first
      return @server_config
    rescue => e
      Rails.logger.error("ERROR - Cannot read first server_configs record")
    end
  end


  private

  # use public layout if no user is logged in
  def determine_layout
    # Rails.logger.debug("*** current_user: #{current_user.inspect.to_s}")
    # Rails.logger.debug("*** layout: #{current_user.nil? ? "public" : "application"}")
    current_user.nil? ? "public" : "application"
  end

end
