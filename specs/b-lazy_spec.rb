
require 'b-lazy'


describe BLazy do

  context "#when_needed" do
  
    it "will not execute the block when no enumeration is performed" do
      BLazy.when_needed{fail; [1, 2, 3]}
    end
    
    
    
    it "executes the block only once" do
      exec_count = 0
      values = BLazy.when_needed{exec_count += 1; [1, 2, 3]}
      exec_count.should == 0
      
      values.next.should == 1
      exec_count.should == 1
      
      values.next.should == 2
      exec_count.should == 1
    end
    
    
  
  end

end

