require 'spec_helper'

describe "SectionShowsFiltersMarkingPeriods", js: true do
  before do
     @school = create :school, marking_periods: 4
    @section = create :section, school: @school, school_year: @school.current_school_year
    @subject = @section.subject

    
    @teacher = create :teacher, school: @school
    create :teaching_assignment, teacher: @teacher, section: @section  
  end

  context "colors the marking period tabs when clicked" do
    before do
      sign_in @teacher
      visit section_path @section 
    end
    it do
      page.evaluate_script("$('#mp_all').css('color');").should eq("rgb(51, 255, 0)")
      (1..4).each do |i|
        page.evaluate_script("$('#mp_#{i}').css('color');").should eq("rgb(51, 51, 51)")
      end
      # Click on second marking period and test again.
      find("#mp_2").click
      page.evaluate_script("$('#mp_2').css('color');").should eq("rgb(51, 255, 0)")
      ["all", "1", "3", "4"].each do |i|
        page.evaluate_script("$('#mp_#{i}').css('color');").should eq("rgb(51, 51, 51)")
      end
      # Click on all marking periods and test again.
      find("#mp_all").click
      page.evaluate_script("$('#mp_all').css('color');").should eq("rgb(51, 255, 0)")
      (1..4).each do |i|
        page.evaluate_script("$('#mp_#{i}').css('color');").should eq("rgb(51, 51, 51)")
      end
    end
  end

  context do
    before do
      @subject_outcome = create :subject_outcome, subject: @subject
       # Bitmask [1]
      @section_outcome = create :section_outcome, subject_outcome: @subject_outcome, 
        section: @section, marking_period: 1, minimized: false
      # Should have Bitmask [3]
      @subject_outcome2 = create :subject_outcome, subject: @subject
      @section_outcome2 = create :section_outcome, subject_outcome: @subject_outcome2, 
        section: @section, marking_period: 4, minimized: false
      sign_in @teacher
      visit section_path @section 
    end

    # This test uses have_(no_)css because the marking periods are hidden when the marking period divs
    # are clicked; they are not removed from the DOM altogether!
    it "hides appropriate outcomes when filters are clicked" do
      mp1_so = @section_outcome.shortened_name
      mp3_so  = @section_outcome2.shortened_name
      page.should have_css('span', text: mp1_so, visible: true)
      page.should have_css('span', text: mp3_so, visible: true)
      find("#mp_1").click
      page.should have_css('span', text: mp1_so, visible: true)
      page.should have_no_css('span', text: mp3_so, visible: true)
      find("#mp_3").click
      page.should have_no_css('span', text: mp1_so, visible: true)
      page.should have_css('span', text: mp3_so, visible: true)
      find("#mp_all").click
      page.should have_css('span', text: mp1_so, visible: true)
      page.should have_css('span', text: mp3_so, visible: true)
    end

    it "persists marking period selections between page refreshes", js: true do
      mp1_so = @section_outcome.shortened_name
      mp3_so  = @section_outcome2.shortened_name

      # Click mp_1 and reload page
      find("#mp_1").click
      visit section_path(@section) #refresh
      # should still display only mp1 selection
      page.evaluate_script("$('#mp_1').css('color');").should eq("rgb(51, 255, 0)")
      page.should have_css('span', text: mp1_so, visible: true)
      page.should have_no_css('span', text: mp3_so, visible: true)

      # Click mp_3 and reload page
      find("#mp_3").click
      visit section_path(@section) #refresh
      # should display only mp3 selection
      page.evaluate_script("$('#mp_3').css('color');").should eq("rgb(51, 255, 0)")
      page.should have_no_css('span', text: mp1_so, visible: true)
      page.should have_css('span', text: mp3_so, visible: true)
    end
  end  
end