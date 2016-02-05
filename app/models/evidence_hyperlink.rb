# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EvidenceHyperlink < ActiveRecord::Base
  attr_accessible :description, :evidence_id, :hyperlink, :title
  before_save :add_http

  belongs_to :evidence, counter_cache: true

  validates :title, presence: true, allow_blank: false
  validates :hyperlink, presence: true, allow_blank: false

  protected
    def add_http
      self.hyperlink = "http://" + hyperlink unless hyperlink[0..3] == "http"
    end
end
