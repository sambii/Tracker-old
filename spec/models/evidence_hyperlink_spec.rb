require 'spec_helper'

describe EvidenceHyperlink do
  before { @evidence_hyperlink = create :evidence_hyperlink }
  
  subject { @evidence_hyperlink }

  it { should be_valid }
  
  context "updates external hyperlinks" do 
  	before { @evidence_hyperlink.update_attributes(hyperlink: "facebook.com") }
    it { @evidence_hyperlink.reload.hyperlink.should eq("http://facebook.com") }
  end
end
