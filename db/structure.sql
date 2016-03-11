CREATE TABLE "announcements" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "content" text, "restrict_to_staff" boolean DEFAULT 'f', "start_at" datetime, "end_at" datetime, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "attendance_types" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "description" varchar(255), "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "school_id" integer, "active" boolean DEFAULT 't');
CREATE TABLE "attendances" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "school_id" integer, "section_id" integer, "user_id" integer, "attendance_date" date, "excuse_id" integer, "attendance_type_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "comment" varchar(255) DEFAULT '');
CREATE TABLE "delayed_jobs" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "priority" integer DEFAULT 0, "attempts" integer DEFAULT 0, "handler" text, "last_error" text, "run_at" datetime, "locked_at" datetime, "failed_at" datetime, "locked_by" varchar(255), "queue" varchar(255), "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "disciplines" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "enrollments" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "student_id" integer, "section_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "student_grade_level" integer, "active" boolean DEFAULT 't', "subsection" integer DEFAULT 0 NOT NULL);
CREATE TABLE "evidence_attachments" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "evidence_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "attachment_file_name" varchar(255), "attachment_content_type" varchar(255), "attachment_file_size" integer, "attachment_updated_at" datetime);
CREATE TABLE "evidence_hyperlinks" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "evidence_id" integer, "title" varchar(255), "hyperlink" varchar(255), "description" text, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "evidence_ratings" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "rating" varchar(255), "comment" varchar(255), "student_id" integer, "evidence_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "evidence_section_outcome_ratings" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "rating" varchar(255), "comment" varchar(255), "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "student_id" integer, "flagged" boolean DEFAULT 'f', "evidence_section_outcome_id" integer);
CREATE TABLE "evidence_section_outcomes" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "evidence_id" integer, "section_outcome_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "position" integer);
CREATE TABLE "evidence_template_subject_outcomes" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "evidence_template_id" integer, "subject_outcome_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "evidence_templates" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "subject_id" integer, "name" varchar(255), "description" text, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "evidence_types" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "evidences" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "assignment_date" date, "position" integer, "section_outcome_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "active" boolean DEFAULT 't', "evidence_type_id" integer, "description" varchar(255), "section_id" integer, "reassessment" boolean DEFAULT 'f', "evidence_attachments_count" integer DEFAULT 0, "evidence_hyperlinks_count" integer DEFAULT 0);
CREATE TABLE "excuses" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "school_id" integer, "code" varchar(255), "description" varchar(255), "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "active" boolean DEFAULT 't');
CREATE TABLE "posts" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer, "parent_id" integer, "header" varchar(255), "body" text, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "top_level_post_id" integer, "attachment_file_name" varchar(255), "attachment_content_type" varchar(255), "attachment_file_size" integer, "attachment_updated_at" datetime);
CREATE TABLE "researchers" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "schema_migrations" ("version" varchar(255) NOT NULL);
CREATE TABLE "school_years" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "school_id" integer, "starts_at" date, "ends_at" date, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "schools" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "acronym" varchar(255), "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "street_address" varchar(255), "city" varchar(255), "state" varchar(255), "zip_code" varchar(255), "marking_periods" integer, "subsection" boolean DEFAULT 'f', "grading_algorithm" varchar(255), "grading_scale" varchar(255), "school_year_id" integer, "flags" varchar(255));
CREATE TABLE "section_attachments" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "section_id" integer, "name" varchar(255), "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "attachment_file_name" varchar(255), "attachment_content_type" varchar(255), "attachment_file_size" integer, "attachment_updated_at" datetime);
CREATE TABLE "section_outcome_attachments" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "section_outcome_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "attachment_file_name" varchar(255), "attachment_content_type" varchar(255), "attachment_file_size" integer, "attachment_updated_at" datetime);
CREATE TABLE "section_outcome_ratings" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "rating" varchar(255), "student_id" integer, "section_outcome_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "section_outcomes" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "section_id" integer, "subject_outcome_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "position" integer, "marking_period" integer, "active" boolean DEFAULT 't', "minimized" boolean DEFAULT 'f');
CREATE TABLE "sections" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "line_number" varchar(255), "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "subject_id" integer, "message" text, "position" integer, "selected_marking_period" integer, "school_year_id" integer);
CREATE TABLE "server_configs" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "district_id" varchar(255) DEFAULT '', "district_name" varchar(255) DEFAULT '', "support_email" varchar(255) DEFAULT 'trackersupport@21pstem.org', "support_team" varchar(255) DEFAULT 'Tracker Support Team', "school_support_team" varchar(255) DEFAULT 'School IT Support Team', "server_url" varchar(255) DEFAULT '', "server_name" varchar(255) DEFAULT 'Tracker System', "web_server_name" varchar(255) DEFAULT 'PARLO Tracker Web Server', "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "subject_outcomes" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "description" varchar(255), "position" integer, "subject_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "essential" boolean DEFAULT 'f', "marking_period" integer, "lo_code" varchar(255) DEFAULT '', "active" boolean DEFAULT 't');
CREATE TABLE "subjects" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "discipline_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "school_id" integer, "subject_manager_id" integer);
CREATE TABLE "system_administrators" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "first_name" varchar(255), "last_name" varchar(255), "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "teaching_assignments" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "teacher_id" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "section_id" integer, "write_access" boolean DEFAULT 't');
CREATE TABLE "teaching_resources" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "discipline_id" integer, "title" varchar(255), "url" varchar(255), "description" text, "position" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "email" varchar(255) DEFAULT '' NOT NULL, "encrypted_password" varchar(255) DEFAULT '' NOT NULL, "reset_password_token" varchar(255), "reset_password_sent_at" datetime, "remember_created_at" datetime, "sign_in_count" integer DEFAULT 0, "current_sign_in_at" datetime, "last_sign_in_at" datetime, "current_sign_in_ip" varchar(255), "last_sign_in_ip" varchar(255), "username" varchar(255), "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "temporary_password" varchar(255), "first_name" varchar(255), "last_name" varchar(255), "school_id" integer, "grade_level" integer, "gender" varchar(255), "counselor" boolean, "school_administrator" boolean, "student" boolean, "system_administrator" boolean, "teacher" boolean, "xid" varchar(255), "child_id" integer DEFAULT 0, "parent" boolean DEFAULT 'f', "street_address" varchar(255), "city" varchar(255), "state" varchar(255), "zip_code" varchar(255), "phone" varchar(255), "absences" integer, "tardies" integer, "attendance_rate" integer, "active" boolean DEFAULT 't', "mastery_level" varchar(255), "subscription_status" varchar(255), "researcher" boolean DEFAULT 'f', "race" varchar(255), "special_ed" boolean DEFAULT 'f', "permissions" varchar(255), "duties" varchar(255));
CREATE INDEX "altered_enrollments_multi" ON "enrollments" ("section_id", "active", "student_id");
CREATE INDEX "altered_enrollments_multi2" ON "enrollments" ("section_id", "active", "subsection");
CREATE INDEX "altered_enrollments_multi3" ON "enrollments" ("section_id", "active");
CREATE INDEX "altered_enrollments_multi4" ON "enrollments" ("section_id", "subsection");
CREATE INDEX "altered_subject_outcomes_multi" ON "subject_outcomes" ("subject_id", "description");
CREATE INDEX "delayed_jobs_priority" ON "delayed_jobs" ("priority", "run_at");
CREATE INDEX "evidence_section_outcome_ratings_multi" ON "evidence_section_outcome_ratings" ("evidence_section_outcome_id", "student_id");
CREATE INDEX "evidence_section_outcome_ratings_on_eso_id" ON "evidence_section_outcome_ratings" ("evidence_section_outcome_id");
CREATE INDEX "evidences_multi" ON "evidences" ("active", "position");
CREATE INDEX "index_announcements_on_end_at" ON "announcements" ("end_at");
CREATE INDEX "index_announcements_on_restrict_to_staff" ON "announcements" ("restrict_to_staff");
CREATE INDEX "index_announcements_on_start_at" ON "announcements" ("start_at");
CREATE INDEX "index_attendance_types_on_school_id" ON "attendance_types" ("school_id");
CREATE INDEX "index_attendances_on_attendance_type_id" ON "attendances" ("attendance_type_id");
CREATE INDEX "index_attendances_on_excuse_id" ON "attendances" ("excuse_id");
CREATE INDEX "index_attendances_on_school_id" ON "attendances" ("school_id");
CREATE INDEX "index_attendances_on_section_id" ON "attendances" ("section_id");
CREATE INDEX "index_attendances_on_user_id" ON "attendances" ("user_id");
CREATE INDEX "index_disciplines_on_name" ON "disciplines" ("name");
CREATE INDEX "index_enrollments_on_active" ON "enrollments" ("active");
CREATE INDEX "index_enrollments_on_section_id" ON "enrollments" ("section_id");
CREATE INDEX "index_enrollments_on_student_id" ON "enrollments" ("student_id");
CREATE INDEX "index_enrollments_on_subsection" ON "enrollments" ("subsection");
CREATE INDEX "index_evidence_attachments_on_evidence_id" ON "evidence_attachments" ("evidence_id");
CREATE INDEX "index_evidence_hyperlinks_on_evidence_id" ON "evidence_hyperlinks" ("evidence_id");
CREATE INDEX "index_evidence_ratings_on_evidence_id" ON "evidence_ratings" ("evidence_id");
CREATE INDEX "index_evidence_ratings_on_student_id" ON "evidence_ratings" ("student_id");
CREATE INDEX "index_evidence_section_outcome_ratings_on_student_id" ON "evidence_section_outcome_ratings" ("student_id");
CREATE INDEX "index_evidence_section_outcomes_on_evidence_id" ON "evidence_section_outcomes" ("evidence_id");
CREATE INDEX "index_evidence_section_outcomes_on_position" ON "evidence_section_outcomes" ("position");
CREATE INDEX "index_evidence_section_outcomes_on_section_outcome_id" ON "evidence_section_outcomes" ("section_outcome_id");
CREATE INDEX "index_evidence_template_subject_outcomes_on_evidence_template_id" ON "evidence_template_subject_outcomes" ("evidence_template_id");
CREATE INDEX "index_evidence_template_subject_outcomes_on_subject_outcome_id" ON "evidence_template_subject_outcomes" ("subject_outcome_id");
CREATE INDEX "index_evidence_templates_on_subject_id" ON "evidence_templates" ("subject_id");
CREATE INDEX "index_evidences_on_evidence_type_id" ON "evidences" ("evidence_type_id");
CREATE INDEX "index_evidences_on_section_id" ON "evidences" ("section_id");
CREATE INDEX "index_excuses_on_school_id" ON "excuses" ("school_id");
CREATE INDEX "index_posts_on_parent_id" ON "posts" ("parent_id");
CREATE INDEX "index_posts_on_top_level_post_id" ON "posts" ("top_level_post_id");
CREATE INDEX "index_posts_on_user_id" ON "posts" ("user_id");
CREATE INDEX "index_school_years_on_school_id" ON "school_years" ("school_id");
CREATE INDEX "index_schools_on_school_year_id" ON "schools" ("school_year_id");
CREATE INDEX "index_section_attachments_on_section_id" ON "section_attachments" ("section_id");
CREATE INDEX "index_section_outcome_attachments_on_section_outcome_id" ON "section_outcome_attachments" ("section_outcome_id");
CREATE INDEX "index_section_outcome_ratings_on_section_outcome_id" ON "section_outcome_ratings" ("section_outcome_id");
CREATE INDEX "index_section_outcome_ratings_on_student_id" ON "section_outcome_ratings" ("student_id");
CREATE INDEX "index_section_outcomes_on_active" ON "section_outcomes" ("active");
CREATE INDEX "index_section_outcomes_on_position" ON "section_outcomes" ("position");
CREATE INDEX "index_section_outcomes_on_section_id" ON "section_outcomes" ("section_id");
CREATE INDEX "index_section_outcomes_on_subject_outcome_id" ON "section_outcomes" ("subject_outcome_id");
CREATE INDEX "index_sections_on_school_year_id" ON "sections" ("school_year_id");
CREATE INDEX "index_sections_on_subject_id" ON "sections" ("subject_id");
CREATE INDEX "index_subject_outcomes_on_subject_id" ON "subject_outcomes" ("subject_id");
CREATE INDEX "index_subjects_on_discipline_id" ON "subjects" ("discipline_id");
CREATE INDEX "index_subjects_on_school_id" ON "subjects" ("school_id");
CREATE INDEX "index_subjects_on_subject_manager_id" ON "subjects" ("subject_manager_id");
CREATE INDEX "index_teaching_assignments_on_section_id" ON "teaching_assignments" ("section_id");
CREATE INDEX "index_teaching_assignments_on_teacher_id" ON "teaching_assignments" ("teacher_id");
CREATE INDEX "index_teaching_resources_on_discipline_id" ON "teaching_resources" ("discipline_id");
CREATE INDEX "index_teaching_resources_on_title" ON "teaching_resources" ("title");
CREATE INDEX "index_users_on_active" ON "users" ("active");
CREATE INDEX "index_users_on_last_name_and_first_name" ON "users" ("last_name", "first_name");
CREATE UNIQUE INDEX "index_users_on_reset_password_token" ON "users" ("reset_password_token");
CREATE INDEX "index_users_on_school_id" ON "users" ("school_id");
CREATE INDEX "index_users_on_school_id_and_child_id" ON "users" ("school_id", "child_id");
CREATE INDEX "index_users_on_school_id_and_counselor" ON "users" ("school_id", "counselor");
CREATE INDEX "index_users_on_school_id_and_grade_level" ON "users" ("school_id", "grade_level");
CREATE INDEX "index_users_on_school_id_and_parent" ON "users" ("school_id", "parent");
CREATE INDEX "index_users_on_school_id_and_researcher" ON "users" ("school_id", "researcher");
CREATE INDEX "index_users_on_school_id_and_school_administrator" ON "users" ("school_id", "school_administrator");
CREATE INDEX "index_users_on_school_id_and_special_ed" ON "users" ("school_id", "special_ed");
CREATE INDEX "index_users_on_school_id_and_student" ON "users" ("school_id", "student");
CREATE INDEX "index_users_on_school_id_and_system_administrator" ON "users" ("school_id", "system_administrator");
CREATE INDEX "index_users_on_school_id_and_teacher" ON "users" ("school_id", "teacher");
CREATE INDEX "index_users_on_school_id_and_xid" ON "users" ("school_id", "xid");
CREATE INDEX "index_users_on_subscription_status" ON "users" ("subscription_status");
CREATE UNIQUE INDEX "index_users_on_username" ON "users" ("username");
CREATE INDEX "section_outcome_ratings_multi" ON "section_outcome_ratings" ("student_id", "section_outcome_id");
CREATE INDEX "section_outcomes_multi" ON "section_outcomes" ("section_id", "active", "position");
CREATE INDEX "student_alphabetical" ON "users" ("student", "active", "last_name", "first_name");
CREATE INDEX "teacher_alphabetical" ON "users" ("teacher", "active", "last_name", "first_name");
CREATE INDEX "teaching_assignments_multi" ON "teaching_assignments" ("teacher_id", "section_id");
CREATE UNIQUE INDEX "unique_schema_migrations" ON "schema_migrations" ("version");
INSERT INTO schema_migrations (version) VALUES ('20110518170412');

INSERT INTO schema_migrations (version) VALUES ('20110518180455');

INSERT INTO schema_migrations (version) VALUES ('20110518181516');

INSERT INTO schema_migrations (version) VALUES ('20110518194714');

INSERT INTO schema_migrations (version) VALUES ('20110518195525');

INSERT INTO schema_migrations (version) VALUES ('20110518200526');

INSERT INTO schema_migrations (version) VALUES ('20110519124053');

INSERT INTO schema_migrations (version) VALUES ('20110519124120');

INSERT INTO schema_migrations (version) VALUES ('20110519130735');

INSERT INTO schema_migrations (version) VALUES ('20110519190934');

INSERT INTO schema_migrations (version) VALUES ('20110519190942');

INSERT INTO schema_migrations (version) VALUES ('20110519191010');

INSERT INTO schema_migrations (version) VALUES ('20110519192515');

INSERT INTO schema_migrations (version) VALUES ('20110519210108');

INSERT INTO schema_migrations (version) VALUES ('20110520125956');

INSERT INTO schema_migrations (version) VALUES ('20110520130051');

INSERT INTO schema_migrations (version) VALUES ('20110520131501');

INSERT INTO schema_migrations (version) VALUES ('20110520172921');

INSERT INTO schema_migrations (version) VALUES ('20110523132425');

INSERT INTO schema_migrations (version) VALUES ('20110524130213');

INSERT INTO schema_migrations (version) VALUES ('20110524150603');

INSERT INTO schema_migrations (version) VALUES ('20110524183131');

INSERT INTO schema_migrations (version) VALUES ('20110525143331');

INSERT INTO schema_migrations (version) VALUES ('20110608125956');

INSERT INTO schema_migrations (version) VALUES ('20110609193600');

INSERT INTO schema_migrations (version) VALUES ('20110609194051');

INSERT INTO schema_migrations (version) VALUES ('20110613201449');

INSERT INTO schema_migrations (version) VALUES ('20110616130711');

INSERT INTO schema_migrations (version) VALUES ('20110616130818');

INSERT INTO schema_migrations (version) VALUES ('20110616132710');

INSERT INTO schema_migrations (version) VALUES ('20110616170112');

INSERT INTO schema_migrations (version) VALUES ('20110616170246');

INSERT INTO schema_migrations (version) VALUES ('20110620130613');

INSERT INTO schema_migrations (version) VALUES ('20110621191416');

INSERT INTO schema_migrations (version) VALUES ('20110629125840');

INSERT INTO schema_migrations (version) VALUES ('20110630175756');

INSERT INTO schema_migrations (version) VALUES ('20110718183432');

INSERT INTO schema_migrations (version) VALUES ('20110719190421');

INSERT INTO schema_migrations (version) VALUES ('20110810143710');

INSERT INTO schema_migrations (version) VALUES ('20110810164040');

INSERT INTO schema_migrations (version) VALUES ('20110810174505');

INSERT INTO schema_migrations (version) VALUES ('20110810190548');

INSERT INTO schema_migrations (version) VALUES ('20110815180918');

INSERT INTO schema_migrations (version) VALUES ('20110817131139');

INSERT INTO schema_migrations (version) VALUES ('20110902025222');

INSERT INTO schema_migrations (version) VALUES ('20110913201846');

INSERT INTO schema_migrations (version) VALUES ('20110913202425');

INSERT INTO schema_migrations (version) VALUES ('20110913231829');

INSERT INTO schema_migrations (version) VALUES ('20110914200559');

INSERT INTO schema_migrations (version) VALUES ('20110916164240');

INSERT INTO schema_migrations (version) VALUES ('20111014145540');

INSERT INTO schema_migrations (version) VALUES ('20111018153229');

INSERT INTO schema_migrations (version) VALUES ('20111018193350');

INSERT INTO schema_migrations (version) VALUES ('20111018193539');

INSERT INTO schema_migrations (version) VALUES ('20111020133630');

INSERT INTO schema_migrations (version) VALUES ('20111027144422');

INSERT INTO schema_migrations (version) VALUES ('20111115150259');

INSERT INTO schema_migrations (version) VALUES ('20120613143418');

INSERT INTO schema_migrations (version) VALUES ('20120613143530');

INSERT INTO schema_migrations (version) VALUES ('20120613145421');

INSERT INTO schema_migrations (version) VALUES ('20120613152056');

INSERT INTO schema_migrations (version) VALUES ('20120619134432');

INSERT INTO schema_migrations (version) VALUES ('20120619134630');

INSERT INTO schema_migrations (version) VALUES ('20120619134645');

INSERT INTO schema_migrations (version) VALUES ('20120621172257');

INSERT INTO schema_migrations (version) VALUES ('20120621172825');

INSERT INTO schema_migrations (version) VALUES ('20120716182405');

INSERT INTO schema_migrations (version) VALUES ('20120718154723');

INSERT INTO schema_migrations (version) VALUES ('20120725140706');

INSERT INTO schema_migrations (version) VALUES ('20120725140727');

INSERT INTO schema_migrations (version) VALUES ('20120731173812');

INSERT INTO schema_migrations (version) VALUES ('20120801174331');

INSERT INTO schema_migrations (version) VALUES ('20120801181239');

INSERT INTO schema_migrations (version) VALUES ('20120809151805');

INSERT INTO schema_migrations (version) VALUES ('20120809152612');

INSERT INTO schema_migrations (version) VALUES ('20120823132559');

INSERT INTO schema_migrations (version) VALUES ('20120828133245');

INSERT INTO schema_migrations (version) VALUES ('20120828133339');

INSERT INTO schema_migrations (version) VALUES ('20120829135006');

INSERT INTO schema_migrations (version) VALUES ('20120829142021');

INSERT INTO schema_migrations (version) VALUES ('20120830191839');

INSERT INTO schema_migrations (version) VALUES ('20120830192530');

INSERT INTO schema_migrations (version) VALUES ('20121001230145');

INSERT INTO schema_migrations (version) VALUES ('20121002131544');

INSERT INTO schema_migrations (version) VALUES ('20121003142920');

INSERT INTO schema_migrations (version) VALUES ('20121004193804');

INSERT INTO schema_migrations (version) VALUES ('20121009210250');

INSERT INTO schema_migrations (version) VALUES ('20121023142332');

INSERT INTO schema_migrations (version) VALUES ('20121024154250');

INSERT INTO schema_migrations (version) VALUES ('20121024171119');

INSERT INTO schema_migrations (version) VALUES ('20121025132639');

INSERT INTO schema_migrations (version) VALUES ('20121115175821');

INSERT INTO schema_migrations (version) VALUES ('20121127142421');

INSERT INTO schema_migrations (version) VALUES ('20121127152025');

INSERT INTO schema_migrations (version) VALUES ('20130731160257');

INSERT INTO schema_migrations (version) VALUES ('20130731160258');

INSERT INTO schema_migrations (version) VALUES ('20130731160259');

INSERT INTO schema_migrations (version) VALUES ('20130802193906');

INSERT INTO schema_migrations (version) VALUES ('20130807153215');

INSERT INTO schema_migrations (version) VALUES ('20130812151159');

INSERT INTO schema_migrations (version) VALUES ('20130812151245');

INSERT INTO schema_migrations (version) VALUES ('20130812151738');

INSERT INTO schema_migrations (version) VALUES ('20130815222320');

INSERT INTO schema_migrations (version) VALUES ('20130822160114');

INSERT INTO schema_migrations (version) VALUES ('20130822163420');

INSERT INTO schema_migrations (version) VALUES ('20130823133443');

INSERT INTO schema_migrations (version) VALUES ('20130823133728');

INSERT INTO schema_migrations (version) VALUES ('20130904171714');

INSERT INTO schema_migrations (version) VALUES ('20130917171150');

INSERT INTO schema_migrations (version) VALUES ('20130930183237');

INSERT INTO schema_migrations (version) VALUES ('20131016151638');

INSERT INTO schema_migrations (version) VALUES ('20131016165725');

INSERT INTO schema_migrations (version) VALUES ('20131022212210');

INSERT INTO schema_migrations (version) VALUES ('20131217225729');

INSERT INTO schema_migrations (version) VALUES ('20150729153000');

INSERT INTO schema_migrations (version) VALUES ('20151013175547');

INSERT INTO schema_migrations (version) VALUES ('20151214215007');

INSERT INTO schema_migrations (version) VALUES ('20160211175640');