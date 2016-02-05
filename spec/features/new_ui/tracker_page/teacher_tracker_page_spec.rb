require 'spec_helper'

require 'shared/common_layout_shared'
require 'shared/common_tracker_header_shared'

describe "SectionShows" do
  before do
    init_all_factories
  end


  describe "as teacher" do
    let(:user) { @teacher }
    let(:password) { @teacher.password }
    it_behaves_like "common_layout_shared"
    it_behaves_like "common_tracker_header_shared"
  end

end