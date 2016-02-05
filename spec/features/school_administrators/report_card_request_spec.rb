require 'spec_helper'

shared_examples_for 'report card request form' do
	it do
		should have_selector 'form#new_report_card_request'
		should have_selector 'form select#report_card_request_grade_level'
		should have_selector "form .submit input[type='submit']"
	end
end

shared_examples_for 'cannot generate report card' do
	it { current_path.should_not == report_card_path }
end

describe "ReportCardRequest" do 

	subject { page }

	before do
		@school = create :school
		@school_administrator = create :school_administrator, school: @school
	end

	describe 'Navigation as School Administrator' do
		before { sign_in(@school_administrator, @school_administrator.password) } 
		it { should have_link 'Generate Report Cards', href: report_card_path }
		
		describe "Click Generate Report Cards" do
			before { click_link 'Generate Report Cards'}
			it_should_behave_like 'report card request form'
		end
	end

	describe 'Generate report card, grade level has student' do
		before do
			# we must clear the email queue first
			ActionMailer::Base.deliveries.clear

			@grade = 3
		    @student = create :student, school: @school, grade_level: @grade
			sign_in @school_administrator
			
			visit report_card_path
		end

		it 'cause delayed_job to send recieve and completed messages' do 
			select @grade.to_s, from: 'report_card_request_grade_level'
			find("input[value='Request Report Card']").click

			#kick off delayed jobs
			@successes, @failures = Delayed::Worker.new.work_off

			@successes.should == 2
			@failures.should  == 0
			ActionMailer::Base.deliveries.size.should == 2
			ActionMailer::Base.deliveries.first.subject.should == "Recieved: Grade #{@grade} Report Card Request"
			ActionMailer::Base.deliveries.last.subject.should  == "Completed: Grade #{@grade} Report Card Request"
			ActionMailer::Base.deliveries.last.attachments.count.should == 1
		end
	end

	describe 'Generate report card, with no students in the selected grade' do
		before do
			# we must clear the email queue first
			ActionMailer::Base.deliveries.clear

			sign_in(@school_administrator, @school_administrator.password)			
			visit report_card_path
		end

		it 'cause delayed_job to send recieved and no student messages' do 
			@grade = 5
			select @grade.to_s, from: 'report_card_request_grade_level'
			find("input[value='Request Report Card']").click

			#kick off delayed jobs
			@successes, @failures = Delayed::Worker.new.work_off

			@successes.should == 2
			@failures.should  == 0
			ActionMailer::Base.deliveries.size.should == 2
			ActionMailer::Base.deliveries.first.subject.should == "Recieved: Grade #{@grade} Report Card Request"
			ActionMailer::Base.deliveries.last.subject.should  == "No Students Found: Grade #{@grade} Report Card Request"
			ActionMailer::Base.deliveries.last.attachments.count.should == 0
		end
	end

  describe 'when school administrator email is blank' do
    before do
      @school_administrator.email=''
      @school_administrator.save(validate: false)
      sign_in @school_administrator
      visit report_card_path
      select '8', from: 'report_card_request_grade_level'
      find("input[value='Request Report Card']").click
    end
    it { should have_selector "#error_explanation li", text: 'email' }
  end

	describe 'Student cannot generate report card' do
		before do
		    @student = create :student, school: @school
			sign_in @student
			visit report_card_path
		end
		it_should_behave_like 'cannot generate report card'
    end

    describe 'Parent cannot generate report card' do
		before do
		    @student = create :student, school: @school
		    @parent = @student.parent
		    @parent.password = 'password'
		    @parent.password_confirmation = 'password'
		    @parent.temporary_password = nil
		    @parent.save!

			sign_in @parent
			visit report_card_path
		end
		it_should_behave_like 'cannot generate report card'
    end

    describe 'Counselor cannot generate report card' do
		before do 
			@counselor = create :counselor, school: @school
			sign_in @counselor
			visit report_card_path
		end
		it_should_behave_like 'cannot generate report card'
    end

    describe 'Researcher cannot generate report card' do
		before do
			# We don't have a model for researcher
		    @researcher = create :user, researcher:true
			sign_in(@researcher,@researcher.password) 
			visit report_card_path
		end
		it_should_behave_like 'cannot generate report card'
    end
end

