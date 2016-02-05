require 'spec_helper'

describe 'StudentSpec' do 
  before do
    @student = create :student
    @enrollments = create_list :enrollment, 3, student: @student 
  end
  subject { @student }
  
  it { should be_valid }

  it 'changes all enrollment subsections when subsection attribute is changed' do
    @student.subsection = 5
    @student.save
   
    @enrollments.each do |e|
      e.reload.subsection.should == 5
    end
  end
end