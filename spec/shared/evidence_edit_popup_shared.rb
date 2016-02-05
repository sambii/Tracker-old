shared_examples "evidence_edit_popup_shared" do

  # Input Parameters Required:
  #   let(:user) { @some_user }
  #   let(:password) { @some_user.password }

  # initializations:
  #   init_all_factories

  before (:each) do
    sign_in(user, password)
    visit section_path(@section)
  end

  describe "test common for all users", js:true do

    before (:each) do
      page.find("#tracker-table-container tbody.tbody-section[data-so-id='1'] tr[data-eso-id='7'] a.evidence-edit").click
    end

    it "starting test" do
      page.should have_selector('.modal-header h3', text: 'Edit Evidence')
      # fill in form
      check('#evidence_reassessment')

    end

  end # "test common for all users"

end
