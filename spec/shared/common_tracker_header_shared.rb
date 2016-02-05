shared_examples "common_tracker_header_shared" do

  # Input Parameters Required:
  #   let(:user) { @some_user }
  #   let(:password) { @some_user.password }

  # initializations:
  #   init_all_factories

  before do
    sign_in(user, password)
    visit section_path(@section)
  end

  describe "test common tracker headers for all users" do
    let(:user_or_full_name) {
      user.full_name.blank? ?
        user.username :
        user.full_name}

    it "shows the last page visited before the breadcrumbs" do
      find("#breadcrumb-flash .last a").text.should =~ /Last Page/
    end

  end # "test common tracker headers for all users"

end
