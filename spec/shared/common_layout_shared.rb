shared_examples "common_layout_shared" do

  # Input Parameters Required:
  #   let(:user) { @some_user }
  #   let(:password) { @some_user.password }

  # initializations:
  #   init_all_factories

  before do
    sign_in(user, password)
    visit section_path(@section)
  end

  describe "test common for all users" do
    let(:user_or_full_name) {
      user.full_name.blank? ?
        user.username :
        user.full_name}

    it "shows the first name in the header user dropdown" do
      # assuming test data has user first name and last names assigned
      find("#head-user-dropdown a").text.should =~ /^\s#{user.first_name}\s/
    end

    it "shows the username or full name in the sidebar" do
      # assuming test data has user first name and last names assigned
      find("#side-name a").text.should =~ /\s#{user.first_name}\s#{user.last_name}\s/
    end

  end # "test common for all users"

end
