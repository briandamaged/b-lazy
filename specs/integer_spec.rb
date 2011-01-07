
require 'b-lazy'

describe Integer do

  context "#positives" do
    it "starts at 1" do
      Integer.positives.next.should == 1
    end
    
    it "produces an ascending sequence" do
      Integer.positives.grab(10).should == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    end
  end

  
  context "#non_negatives" do
    it "starts at 0" do
      Integer.non_negatives.next.should == 0
    end
    
    it "produces an ascending sequence" do
      Integer.non_negatives.grab(10).should == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    end
  end
  
  
  
  
  
  context "#negatives" do
    it "starts at -1" do
      Integer.negatives.next.should == -1
    end
    
    it "produces a descending sequence" do
      Integer.negatives.grab(10).should == [-1, -2, -3, -4, -5, -6, -7, -8, -9, -10]
    end
  end
  
  
  context "#non_positives" do
    it "starts at 0" do
      Integer.non_positives.next.should == 0
    end
    
    it "produces an ascending sequences" do
      Integer.non_positives.grab(10).should == [0, -1, -2, -3, -4, -5, -6, -7, -8, -9]
    end
  end
  
  
  
  context "#all" do
    it "starts at 0" do
      Integer.all.next.should == 0
    end
    
    it "alternates between positives and negatives" do
      Integer.all.grab(10).should == [0, 1, -1, 2, -2, 3, -3, 4, -4, 5]
    end
  end

end
