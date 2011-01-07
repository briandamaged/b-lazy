
require 'b-lazy'

describe Enumerable do

  let(:list)       { (1..10).to_a             }
  let(:mapping)    { Proc.new{|x| 2 * x}      }
  let(:filter)     { Proc.new{|x| x % 2 == 0} }

  let(:left)       { 3                        }
  let(:left_cond)  { Proc.new{|x| x >= left}  }
  
  let(:right)      { 8                        }
  let(:right_cond) { Proc.new{|x| x <= right} }


  context "#lmap" do

    it "produces one value for each input" do
      list.lmap(&mapping).to_a.size.should == list.size
    end
    
    it "yields the same elements as #map" do
      list.lmap(&mapping).to_a.should == list.map(&mapping)
    end
  end
  
  
  context "#touch" do
    it "ignores the return value of the block" do
      list.touch{|x| 'ignore'}.to_a.should == list
    end
    
    it "allows for the modification of object state" do
      [[1, 2, 3], [4, 5, 6]].touch{|x| x.pop}.to_a.should == [[1, 2], [4, 5]]
    end
  end
  

  context "#lselect" do
    it "yields the same elements as #select" do
      list.lselect(&filter).to_a.should == list.select(&filter)
    end
    
    it "returns all elements when every element satisfies the filter" do
      list.lselect{true}.to_a.should == list
    end
    
    it "returns no elements when none of the elements satisfy the filter" do
      list.lselect{false}.should be_empty
    end
  end
  
  
  context "#lreject" do
    it "yields the same elements as #reject" do
      list.lreject(&filter).to_a.should == list.reject(&filter)
    end
    
    it "returns all elements when none of the elements satisfy the filter" do
      list.lreject{false}.to_a.should == list
    end
    
    it "returns no elements when every element satisfies the filter" do
      list.lreject{true}.should be_empty
    end
  end




  context "#start_when" do
  
    it "starts with the element that satisfied the condition" do
      list.start_when(&left_cond).peek.should == left
    end
    
    it "does not care if subsequent elements fail the condition" do
      [1, 2, 3, 2, 1].start_when(&left_cond).reject(&left_cond).should_not be_empty
    end
    
    it "yields no elements if the condition is never satisfied" do
      list.start_when{false}.should be_empty
    end

  end
  
  
  context "#start_after" do
  
    it "starts with the element after the one that satisfied the condition" do
      list.start_after(&left_cond).peek.should == left + 1
    end
    
    it "does not care if subsequent elements fail the condition" do
      [1, 2, 3, 2, 1].start_after(&left_cond).reject(&left_cond).should_not be_empty
    end
    
    it "yields no elements if the condition is never satisfied" do
      list.start_after{false}.should be_empty
    end

  end




  context "#do_while" do
  
    it "only yields elements for which the condition is true" do
      list.do_while(&right_cond).reject(&right_cond).should be_empty
    end
    
    it "stops yielding elements once the condition becomes false" do
      [1, 2, 3, 4, 5].do_while{|x| x <= 3}.to_a.should == [1, 2, 3]
    end

    it "yields all elements if the condition is always satisfied" do
      list.do_while{true}.to_a.should == list
    end
  end


  context "#do_until" do
    it "only yields elements for which the condition is false" do
      list.do_until(&left_cond).select(&left_cond).should be_empty
    end
    
    it "stops yielding elements once the condition becomes true" do
      [1, 2, 3, 4, 5].do_until{|x| x >= 3}.to_a.should == [1, 2]
    end
    
    
    it "yields no elements if the condition is immediately satisfied" do
      list.do_until{true}.should be_empty
    end
    
    
    it "yields all elements if the condition is never satisfied" do
      list.do_until{false}.to_a.should == list
    end
  end


  context "#stop_when" do
    it "only satisfies the condition with its final element" do
      results = list.stop_when(&left_cond).to_a.map(&left_cond)
      
      # The last element is true
      results[-1].should == true
      
      # All other elements are false
      results.pop
      results.should == [false] * results.length
    end
  
    it "yields exactly one element if the condition is immediately true" do
      list.stop_when{true}.to_a.length.should == 1
    end
    
    it "yields all elements if the condition is never satisfied" do
      list.stop_when{false}.to_a.should == list
    end
  end
  
  
  context "#skip" do
    it "yields all elements when n = 0" do
      list.skip(0).to_a.should == list
    end
    
    it "yields nothing when n exceeds the number of elements" do
      list.skip(list.size + 100).to_a.should be_empty
    end
    
    it "yields [total elements - n] elements when n <= [total elements]" do
      list.skip(3).to_a.size.should == list.size - 3
    end
    
    it "omits the first n elements" do
      list.skip(3).to_a.should == list[3..-1]
    end
  end
  
  
  context "#cons" do
  
    it "combines the elements of Enumerable objects into one Enumerator" do
      [[1, 2, 3], [4, 5], [6]].cons.to_a.should == [1, 2, 3, 4, 5, 6]
    end
    
    it "yields nothing when given an empty Enumerable object" do
      [].cons.should be_empty
    end
  
  end
  
  
  context "#weave" do
  
    it "repeatedly takes one element from each Enumerable" do
      [[1, 2, 3], [4, 5, 6], [7, 8, 9]].weave.to_a.should == [1, 4, 7, 2, 5, 8, 3, 6, 9]
    end
    
    it "discards an Enumerable once it is empty" do
      [[1, 2, 3], [4], [7, 8, 9]].weave.to_a.should == [1, 4, 7, 2, 8, 3, 9]
    end
  end


  context "#diagonalize" do
  
    it "yields nothing when all Enumerables are empty" do
      [[], [], []].diagonalize.should be_empty
    end
    

  
    it "gradually introduces new Enumerables" do
      source = [(1..10).to_a] * 10
      source.diagonalize.take(10).should == [1, 1, 2, 1, 2, 3, 1, 2, 3, 4]
    end
    
    it "handles size mismatches without any surprises" do
      
    end
    
  end


  context "#randomly" do
  
    it "yields each element exactly once" do
      r = list.randomly.to_a
      list.each{|x| r.count(x).should == 1}
    end
    
    it "yields the elements in a random order" do
      # This test has a 1 in 2^100 chance of failing.  Meh.
      (1..100).randomly.to_a.should_not == (1..100)
    end
  
  end


  context "#ltranspose" do

    it "yields arrays with length equal to the number of Enumerables provided" do
      [[1, 2, 3], [4, 5, 6]].ltranspose.map{|x| x.size}.should == [2, 2, 2]
    end
    
    it "yields zero elements when one of its Enumerables is already empty" do
      [[1, 2, 3], [], [7, 8, 9]].ltranspose.should be_empty
    end
    
  end
  
  
  context "#cycle" do
    it "indefinitely repeats the same sequence" do
      (1..3).cycle.take(9).should == [1, 2, 3, 1, 2, 3, 1, 2, 3]
    end
    
    it "yields nothing when performed on an empty Enumerator" do
      [].cycle.take(3).should == []
    end
  end
  
  context "#repeat" do
  
    it "repeats the sequence exactly n times" do
      (1..3).repeat(3).to_a.should == [1, 2, 3, 1, 2, 3, 1, 2, 3]
    end
    
    it "yields nothing when n is less than 1" do
      (1..3).repeat(0).to_a.should == []
    end
    
    it "treats floating-point values of n as floor(n)" do
      (1..3).repeat(2.2).to_a.should == [1, 2, 3, 1, 2, 3]
    end
  
  end
  
  
  context "#ensure_enum" do
    it "returns self when called on an Enumerator" do
      x = [1, 2, 3].each
      x.ensure_enum.should be_equal(x)
    end
    
    it "returns a new Enumerator when called on an Enumerable" do
      x = [1, 2, 3]
      x.ensure_enum.should_not be_equal(x)
    end
  end

end
