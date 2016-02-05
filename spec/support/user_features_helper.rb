
module UserFeaturesHelper
  def set_users_school(school)
    visit schools_path
    assert_match("/schools", current_path)
    click_link(school.name)
    # assert_match("/schools/#{school.id}", current_path)
    page.should have_content(school.name)
  end

  # for use in request specs
  def sign_in user, passwd=nil
    @test_user = user.clone     # save current user saved off for multiple role testing
    passwd ||= user.password
    visit root_path

    fill_in "Username", with: user.username
    fill_in "Password", with: passwd
    click_button "Sign in"
  end

end

