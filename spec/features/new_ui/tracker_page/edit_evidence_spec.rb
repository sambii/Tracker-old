# edit_evidence_spec.rb
require 'spec_helper'

require 'shared/evidence_edit_popup_shared'

describe "EvidenceEditPopup" do
  before do
    init_all_factories
  end

  describe "as teacher" do
    let(:user) { @teacher }
    let(:password) { @teacher.password }
    it_behaves_like "evidence_edit_popup_shared"
  end

end