class ActiveRecord::Base
  before_save :strip_whitespace!

  def strip_whitespace!
    @attributes.each do |attribute, value|
      self[attribute] = value.strip if value.class == String
    end
  end
end
