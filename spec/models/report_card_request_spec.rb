require 'spec_helper'

describe ReportCardRequest do

	before { @report_request = build :report_card_request }

	subject { @report_request }

	it { should be_valid }

	it { should respond_to :grade_level }

	describe "when grade_level is not present" do
		before { @report_request.grade_level = nil }
		it { should_not be_valid }
	end

	describe "with blank grade_level" do
		before { @report_request.grade_level = " " }
		it { should_not be_valid }
	end

	describe "when grade level is to small" do
		before { @report_request.grade_level = 0 }
		it { should_not be_valid }
	end

	describe "when grade level is too large" do
		before { @report_request.grade_level = 13 }
		it { should_not be_valid }
	end

end