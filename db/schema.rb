# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20170125132001) do

  create_table "announcements", :force => true do |t|
    t.text     "content"
    t.boolean  "restrict_to_staff", :default => false
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
  end

  add_index "announcements", ["end_at"], :name => "index_announcements_on_end_at"
  add_index "announcements", ["restrict_to_staff"], :name => "index_announcements_on_restrict_to_staff"
  add_index "announcements", ["start_at"], :name => "index_announcements_on_start_at"

  create_table "attendance_types", :force => true do |t|
    t.string   "description"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "school_id"
    t.boolean  "active",      :default => true
  end

  add_index "attendance_types", ["school_id"], :name => "index_attendance_types_on_school_id"

  create_table "attendances", :force => true do |t|
    t.integer  "school_id"
    t.integer  "section_id"
    t.integer  "user_id"
    t.date     "attendance_date"
    t.integer  "excuse_id"
    t.integer  "attendance_type_id"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "comment",            :default => ""
  end

  add_index "attendances", ["attendance_type_id"], :name => "index_attendances_on_attendance_type_id"
  add_index "attendances", ["excuse_id"], :name => "index_attendances_on_excuse_id"
  add_index "attendances", ["school_id"], :name => "index_attendances_on_school_id"
  add_index "attendances", ["section_id"], :name => "index_attendances_on_section_id"
  add_index "attendances", ["user_id"], :name => "index_attendances_on_user_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "disciplines", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "disciplines", ["name"], :name => "index_disciplines_on_name"

  create_table "enrollments", :force => true do |t|
    t.integer  "student_id"
    t.integer  "section_id"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.integer  "student_grade_level"
    t.boolean  "active",              :default => true
    t.integer  "subsection",          :default => 0,    :null => false
  end

  add_index "enrollments", ["active"], :name => "index_enrollments_on_active"
  add_index "enrollments", ["section_id", "active", "student_id"], :name => "altered_enrollments_multi"
  add_index "enrollments", ["section_id", "active", "subsection"], :name => "altered_enrollments_multi2"
  add_index "enrollments", ["section_id", "active"], :name => "altered_enrollments_multi3"
  add_index "enrollments", ["section_id", "subsection"], :name => "altered_enrollments_multi4"
  add_index "enrollments", ["section_id"], :name => "index_enrollments_on_section_id"
  add_index "enrollments", ["student_id"], :name => "index_enrollments_on_student_id"
  add_index "enrollments", ["subsection"], :name => "index_enrollments_on_subsection"

  create_table "evidence_attachments", :force => true do |t|
    t.string   "name"
    t.integer  "evidence_id"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
  end

  add_index "evidence_attachments", ["evidence_id"], :name => "index_evidence_attachments_on_evidence_id"

  create_table "evidence_hyperlinks", :force => true do |t|
    t.integer  "evidence_id"
    t.string   "title"
    t.string   "hyperlink"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "evidence_hyperlinks", ["evidence_id"], :name => "index_evidence_hyperlinks_on_evidence_id"

  create_table "evidence_ratings", :force => true do |t|
    t.string   "rating"
    t.string   "comment"
    t.integer  "student_id"
    t.integer  "evidence_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "evidence_ratings", ["evidence_id"], :name => "index_evidence_ratings_on_evidence_id"
  add_index "evidence_ratings", ["student_id"], :name => "index_evidence_ratings_on_student_id"

  create_table "evidence_section_outcome_ratings", :force => true do |t|
    t.string   "rating"
    t.string   "comment"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "student_id"
    t.boolean  "flagged",                     :default => false
    t.integer  "evidence_section_outcome_id"
  end

  add_index "evidence_section_outcome_ratings", ["evidence_section_outcome_id", "student_id"], :name => "evidence_section_outcome_ratings_multi"
  add_index "evidence_section_outcome_ratings", ["evidence_section_outcome_id"], :name => "evidence_section_outcome_ratings_on_eso_id"
  add_index "evidence_section_outcome_ratings", ["student_id"], :name => "index_evidence_section_outcome_ratings_on_student_id"

  create_table "evidence_section_outcomes", :force => true do |t|
    t.integer  "evidence_id"
    t.integer  "section_outcome_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.integer  "position"
  end

  add_index "evidence_section_outcomes", ["evidence_id"], :name => "index_evidence_section_outcomes_on_evidence_id"
  add_index "evidence_section_outcomes", ["position"], :name => "index_evidence_section_outcomes_on_position"
  add_index "evidence_section_outcomes", ["section_outcome_id"], :name => "index_evidence_section_outcomes_on_section_outcome_id"

  create_table "evidence_template_subject_outcomes", :force => true do |t|
    t.integer  "evidence_template_id"
    t.integer  "subject_outcome_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "evidence_template_subject_outcomes", ["evidence_template_id"], :name => "index_evidence_template_subject_outcomes_on_evidence_template_id"
  add_index "evidence_template_subject_outcomes", ["subject_outcome_id"], :name => "index_evidence_template_subject_outcomes_on_subject_outcome_id"

  create_table "evidence_templates", :force => true do |t|
    t.integer  "subject_id"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "evidence_templates", ["subject_id"], :name => "index_evidence_templates_on_subject_id"

  create_table "evidence_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "evidences", :force => true do |t|
    t.string   "name"
    t.date     "assignment_date"
    t.integer  "position"
    t.integer  "section_outcome_id"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.boolean  "active",                     :default => true
    t.integer  "evidence_type_id"
    t.string   "description"
    t.integer  "section_id"
    t.boolean  "reassessment",               :default => false
    t.integer  "evidence_attachments_count", :default => 0
    t.integer  "evidence_hyperlinks_count",  :default => 0
  end

  add_index "evidences", ["active", "position"], :name => "evidences_multi"
  add_index "evidences", ["evidence_type_id"], :name => "index_evidences_on_evidence_type_id"
  add_index "evidences", ["id"], :name => "index_evidences_on_id"
  add_index "evidences", ["section_id"], :name => "index_evidences_on_section_id"

  create_table "excuses", :force => true do |t|
    t.integer  "school_id"
    t.string   "code"
    t.string   "description"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "active",      :default => true
  end

  add_index "excuses", ["school_id"], :name => "index_excuses_on_school_id"

  create_table "materials", :force => true do |t|
    t.integer  "user_id",                 :null => false
    t.string   "material_type"
    t.string   "title"
    t.string   "description"
    t.string   "keywords"
    t.string   "url"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "materials", ["id"], :name => "index_materials_on_id"
  add_index "materials", ["user_id"], :name => "index_materials_on_user_id"

  create_table "posts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "parent_id"
    t.string   "header"
    t.text     "body"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.integer  "top_level_post_id"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
  end

  add_index "posts", ["parent_id"], :name => "index_posts_on_parent_id"
  add_index "posts", ["top_level_post_id"], :name => "index_posts_on_top_level_post_id"
  add_index "posts", ["user_id"], :name => "index_posts_on_user_id"

  create_table "researchers", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "school_years", :force => true do |t|
    t.string   "name"
    t.integer  "school_id"
    t.date     "starts_at"
    t.date     "ends_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "school_years", ["school_id"], :name => "index_school_years_on_school_id"

  create_table "schools", :force => true do |t|
    t.string   "name"
    t.string   "acronym"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.string   "street_address"
    t.string   "city"
    t.string   "state"
    t.string   "zip_code"
    t.integer  "marking_periods"
    t.boolean  "subsection",        :default => false
    t.string   "grading_algorithm"
    t.string   "grading_scale"
    t.integer  "school_year_id"
    t.string   "flags"
  end

  add_index "schools", ["school_year_id"], :name => "index_schools_on_school_year_id"

  create_table "section_attachments", :force => true do |t|
    t.integer  "section_id"
    t.string   "name"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
  end

  add_index "section_attachments", ["section_id"], :name => "index_section_attachments_on_section_id"

  create_table "section_outcome_attachments", :force => true do |t|
    t.string   "name"
    t.integer  "section_outcome_id"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
  end

  add_index "section_outcome_attachments", ["section_outcome_id"], :name => "index_section_outcome_attachments_on_section_outcome_id"

  create_table "section_outcome_ratings", :force => true do |t|
    t.string   "rating"
    t.integer  "student_id"
    t.integer  "section_outcome_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "section_outcome_ratings", ["section_outcome_id"], :name => "index_section_outcome_ratings_on_section_outcome_id"
  add_index "section_outcome_ratings", ["student_id", "section_outcome_id"], :name => "section_outcome_ratings_multi"
  add_index "section_outcome_ratings", ["student_id"], :name => "index_section_outcome_ratings_on_student_id"

  create_table "section_outcomes", :force => true do |t|
    t.integer  "section_id"
    t.integer  "subject_outcome_id"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.integer  "position"
    t.integer  "marking_period"
    t.boolean  "active",             :default => true
    t.boolean  "minimized",          :default => false
  end

  add_index "section_outcomes", ["active"], :name => "index_section_outcomes_on_active"
  add_index "section_outcomes", ["position"], :name => "index_section_outcomes_on_position"
  add_index "section_outcomes", ["section_id", "active", "position"], :name => "section_outcomes_multi"
  add_index "section_outcomes", ["section_id"], :name => "index_section_outcomes_on_section_id"
  add_index "section_outcomes", ["subject_outcome_id"], :name => "index_section_outcomes_on_subject_outcome_id"

  create_table "sections", :force => true do |t|
    t.string   "line_number"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.integer  "subject_id"
    t.text     "message"
    t.integer  "position"
    t.integer  "selected_marking_period"
    t.integer  "school_year_id"
  end

  add_index "sections", ["school_year_id"], :name => "index_sections_on_school_year_id"
  add_index "sections", ["subject_id"], :name => "index_sections_on_subject_id"

  create_table "server_configs", :force => true do |t|
    t.string   "district_id",         :default => ""
    t.string   "district_name",       :default => ""
    t.string   "support_email",       :default => "trackersupport@21pstem.org"
    t.string   "support_team",        :default => "Tracker Support Team"
    t.string   "school_support_team", :default => "School IT Support Team"
    t.string   "server_url",          :default => ""
    t.string   "server_name",         :default => "Tracker System"
    t.string   "web_server_name",     :default => "PARLO Tracker Web Server"
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.string   "flags",               :default => ""
  end

  create_table "student_eso_uploads", :force => true do |t|
    t.integer  "user_id",                     :null => false
    t.integer  "evidence_section_outcome_id", :null => false
    t.integer  "material_id",                 :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  add_index "student_eso_uploads", ["evidence_section_outcome_id", "material_id"], :name => "ix_student_eso_materials_eso_upload"
  add_index "student_eso_uploads", ["id"], :name => "index_student_eso_uploads_on_id"
  add_index "student_eso_uploads", ["material_id", "evidence_section_outcome_id"], :name => "ix_student_eso_materials_upload_eso"
  add_index "student_eso_uploads", ["user_id"], :name => "index_student_eso_uploads_on_user_id"

  create_table "subject_outcomes", :force => true do |t|
    t.string   "description"
    t.integer  "position"
    t.integer  "subject_id"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.boolean  "essential",      :default => false
    t.integer  "marking_period"
    t.string   "lo_code",        :default => ""
    t.boolean  "active",         :default => true
    t.integer  "model_lo_id"
  end

  add_index "subject_outcomes", ["subject_id", "description"], :name => "altered_subject_outcomes_multi"
  add_index "subject_outcomes", ["subject_id"], :name => "index_subject_outcomes_on_subject_id"

  create_table "subjects", :force => true do |t|
    t.string   "name"
    t.integer  "discipline_id"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.integer  "school_id"
    t.integer  "subject_manager_id"
    t.string   "bulk_lo_seq_year"
    t.datetime "bulk_lo_seq_timestamp"
    t.boolean  "active"
  end

  add_index "subjects", ["discipline_id"], :name => "index_subjects_on_discipline_id"
  add_index "subjects", ["school_id"], :name => "index_subjects_on_school_id"
  add_index "subjects", ["subject_manager_id"], :name => "index_subjects_on_subject_manager_id"

  create_table "system_administrators", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "teaching_assignments", :force => true do |t|
    t.integer  "teacher_id"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "section_id"
    t.boolean  "write_access", :default => true
  end

  add_index "teaching_assignments", ["section_id"], :name => "index_teaching_assignments_on_section_id"
  add_index "teaching_assignments", ["teacher_id", "section_id"], :name => "teaching_assignments_multi"
  add_index "teaching_assignments", ["teacher_id"], :name => "index_teaching_assignments_on_teacher_id"

  create_table "teaching_resources", :force => true do |t|
    t.integer  "discipline_id"
    t.string   "title"
    t.string   "url"
    t.text     "description"
    t.integer  "position"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "teaching_resources", ["discipline_id"], :name => "index_teaching_resources_on_discipline_id"
  add_index "teaching_resources", ["title"], :name => "index_teaching_resources_on_title"

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "",    :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "username"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "temporary_password"
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "school_id"
    t.integer  "grade_level"
    t.string   "gender"
    t.boolean  "counselor"
    t.boolean  "school_administrator"
    t.boolean  "student"
    t.boolean  "system_administrator"
    t.boolean  "teacher"
    t.string   "xid"
    t.integer  "child_id",               :default => 0
    t.boolean  "parent",                 :default => false
    t.string   "street_address"
    t.string   "city"
    t.string   "state"
    t.string   "zip_code"
    t.string   "phone"
    t.integer  "absences"
    t.integer  "tardies"
    t.integer  "attendance_rate"
    t.boolean  "active",                 :default => true
    t.string   "mastery_level"
    t.string   "subscription_status"
    t.boolean  "researcher",             :default => false
    t.string   "race"
    t.boolean  "special_ed",             :default => false
    t.string   "permissions"
    t.string   "duties"
  end

  add_index "users", ["active"], :name => "index_users_on_active"
  add_index "users", ["id"], :name => "index_users_on_id"
  add_index "users", ["last_name", "first_name"], :name => "index_users_on_last_name_and_first_name"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["school_id", "child_id"], :name => "index_users_on_school_id_and_child_id"
  add_index "users", ["school_id", "counselor"], :name => "index_users_on_school_id_and_counselor"
  add_index "users", ["school_id", "grade_level"], :name => "index_users_on_school_id_and_grade_level"
  add_index "users", ["school_id", "parent"], :name => "index_users_on_school_id_and_parent"
  add_index "users", ["school_id", "researcher"], :name => "index_users_on_school_id_and_researcher"
  add_index "users", ["school_id", "school_administrator"], :name => "index_users_on_school_id_and_school_administrator"
  add_index "users", ["school_id", "special_ed"], :name => "index_users_on_school_id_and_special_ed"
  add_index "users", ["school_id", "student"], :name => "index_users_on_school_id_and_student"
  add_index "users", ["school_id", "system_administrator"], :name => "index_users_on_school_id_and_system_administrator"
  add_index "users", ["school_id", "teacher"], :name => "index_users_on_school_id_and_teacher"
  add_index "users", ["school_id", "xid"], :name => "index_users_on_school_id_and_xid"
  add_index "users", ["school_id"], :name => "index_users_on_school_id"
  add_index "users", ["student", "active", "last_name", "first_name"], :name => "student_alphabetical"
  add_index "users", ["subscription_status"], :name => "index_users_on_subscription_status"
  add_index "users", ["teacher", "active", "last_name", "first_name"], :name => "teacher_alphabetical"
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

end
