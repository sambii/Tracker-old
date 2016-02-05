
# For validating the columns in your database for a model
def test_has_fields array
	array.each do |field|
       describe "field #{field} should have setters and getters" do
   	   	it { should respond_to("#{field}") }
   	   	it { should respond_to("#{field}=") }
   	   end
   	end
end

# For validating methods that provide useful information about a model object
def test_responds_to_methods array
	array.each do |m|
	    	describe "method #{m} should be callable" do
	   			it { should respond_to("#{m}") }
	   		end
	end
end

# For validating that the relationships for your model exist
def test_has_relationships array
	array.each do |rel|
		describe "should have #{rel} relationship" do
   		   it { should respond_to("#{rel}") }
   		end
    end
end
