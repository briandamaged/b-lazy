

# We really don't need to make any significant changes
# to the Enumerator class itself.  We're just adding a
# few convenient methods that can simplify looping constructs.
class Enumerator

  # If the Enumerator is empty, then return false.  Otherwise,
  # return true.
  def has_next?
    peek
    true
  rescue StopIteration
    false
  end
  
  
  # If the Enumerator is empty, then return true.  Otherwise,
  # return false.
  def empty?
    peek
    false
  rescue StopIteration
    true
  end


  # This is similar to the #take method, except that it
  # actually moves the Enumerator ahead n after each call.
  def grab(n)
    retval = []
    begin
      n.times{retval << self.next}
    rescue StopIteration
    end
    retval
  end
  
end




module Enumerable


  def lmap(&blk)
    Enumerator.new do |out|
      self.each do |i|
        out.yield blk.call(i)
      end
    end
  end
  
  
  # This is similar to the tap method, but it operates on
  # each element of the Enumerator as it passes through.
  # This is useful for many things, such as:
  #
  # 1. Examining the state of the element
  # 2. Logging
  # 3. Modifying the element's state
  # 4. Recording interim values
  def touch(&blk)
    Enumerator.new do |out|
      self.each do |x|
        blk.call x
        out.yield x
      end
    end
  end
  
  
  # This is the same as the #select method except that it
  # operates lazily.
  def lselect(&blk)
    Enumerator.new do |out|
      self.each do |i|
        out.yield i if blk.call(i)
      end
    end
  end
  
  
  # This is the same as the #reject method except that it
  # operates lazily.
  def lreject(&blk)
    Enumerator.new do |out|
      self.each do |i|
        out.yield i unless blk.call(i)
      end
    end
  end


  # Begins yielding values as soon as the condition becomes true.
  def start_when(&blk)
    Enumerator.new do |out|
      s = self.ensure_enum
      loop do
        break if blk.call(s.peek)
        s.next
      end
      
      loop do
        out.yield s.next
      end
    end
  end
  
  
  # Start one element after the condition becomes true
  def start_after(&blk)
    Enumerator.new do |out|
      s = self.ensure_enum
      loop do
        break if blk.call(s.next)
      end
      
      loop do
        out.yield s.next
      end
    end
  end
  

  # Continue as long as the condition is true
  def do_while(&blk)
    s = self.ensure_enum
    Enumerator.new do |out|
      while s.has_next?
        break unless blk.call(s.peek)
        out.yield s.next
      end
    end
  end


  # Keep iterating until the condition becomes true
  def do_until(&blk)
    s = self.ensure_enum
    Enumerator.new do |out|
      until s.empty?
        break if blk.call(s.peek)
        out.yield s.next
      end
    end
  end
  alias :stop_before :do_until
  
  
  # Returns all elements up to and including the element
  # the causes the condition to become true.
  def stop_when(&blk)
    s = self.ensure_enum
    Enumerator.new do |out|
      while s.has_next?
        out.yield s.peek
        break if blk.call(s.next)
      end
    end
  end


  # Skips the specified number of elements.  Note that this
  # method does not complain if the Enumerator is empty.
  def skip(n = 1)
    Enumerator.new do |out|
      s = self.ensure_enum
      begin
        n.times {s.next}
        loop do
          out.yield s.next
        end
      rescue StopIteration
      end
    end
  end


  # In Java-speak, we would say this method operates on
  # Enumerable<Enumerable<?>> .  It concatenates the values
  # of each nested Enumerable and produces one Enumerable that
  # contains all of the values.  For example:
  #
  # [[1, 2, 3], [4, 5]].cons.to_a -> [1, 2, 3, 4, 5]
  def cons()
    Enumerator.new do |out|
      s  = self.ensure_enum
      loop do
        items = s.next.ensure_enum
        loop do
          out.yield items.next
        end
      end
    end
  end
  
  
  # This is similar to cons, but it
  # instead takes the first item from each enumerator,
  # then the second item, etc.  This can be handy when
  # you have a finite number of enumerators, but each
  # one may hold an infinite number of items
  def weave()
    Enumerator.new do |out|
      enums = self.ensure_enum.lmap(&:ensure_enum)
      
      while enums.has_next? do
        # We to_a each iteration to avoid creating a huge
        # Enumerator stack.
        enums = enums.lselect{|e| e.has_next?}.touch{|e| out.yield e.next}.to_a.ensure_enum
      end
    end
  end


  # If you have an infinite number of Enumerators, and each of these
  # have an infinite number of elements, then you should iterate over
  # them using Cantor's diagonalization technique.  As t -> infinity,
  # you will examine all elements from all Enumerators.
  def diagonalize()
    Enumerator.new do |out|
      s = self.ensure_enum
      enums = []
      while s.has_next? do
        enums.unshift s.next.ensure_enum
        enums = enums.lselect{|e| e.has_next?}.touch{|e| out.yield e.next}.to_a
      end
      
      # Nothing else in s.  Just weave the remaining elements
      enums.weave.each{|x| out.yield x}
    end
  end
  
  
  # Randomizes the order in which the elements are yielded.  Since
  # this is done in a lazy fashion, it is not as random as actually
  # shuffling the entire list.
  def randomly(n = 8)
    Enumerator.new do |out|
      s = self.ensure_enum
      pool = s.grab(n)
      while s.has_next?
        index = rand(n)
        out.yield pool[index]
        pool[index] = s.next
      end
      pool.sort_by{rand}.each{|x| out.yield x}
    end
  end


  # This is similar to Array's transpose method, but it can operate
  # on any Enumerable.  Additionally, it stops as soon as the first
  # Enumerable is exhausted (rather than setting the missing values
  # equal to nil).
  def ltranspose()
    Enumerator.new do |out|
      catch(:nothing_to_do) do
        # If any Enumerable is empty, then yield nothing
        enums = self.lmap{|e| e.ensure_enum}.
                     touch{|e| throw :nothing_to_do if e.empty?}.
                     to_a
        
        loop do
          out.yield enums.map{|e| e.next}
        end
      end
    end
  end



  # Keeps repeating the same elements indefinitely.
  def cycle()
    Enumerator.new do |out|
      values = self.touch{|x| out.yield x}.to_a
      unless values.empty?
        loop do
          values.each{|x| out.yield x}
        end
      end
    end
  end
  
  

  
  
  # Repeats the same sequence of elements n times.
  def repeat(n)
    n = n.to_i
    Enumerator.new do |out|
      if n >= 1
        values = self.touch{|x| out.yield x}.to_a
        (n - 1).times{ values.each{|x| out.yield x} }
      end
    end
  end


  # When #to_enum is called on an Enumerator, it creates a copy
  # and rewinds it (when possible).  Unfortunately, this is
  # not actually the behavior that we want; we just want to make
  # sure that we're operating on an Enumerator.  So, this method
  # calls #to_enum only if it is necessary.
  def ensure_enum()
    if self.kind_of? Enumerator
      self
    else
      self.to_enum
    end
  end

end





class Integer

  

  def self.positives
    (1..Float::INFINITY).ensure_enum
  end
  
  def self.non_negatives
    (0..Float::INFINITY).ensure_enum
  end
  
  def self.negatives
    positives.lmap{|x| -1 * x}
  end
  
  def self.non_positives
    non_negatives.lmap{|x| -1 * x}
  end
  
  def self.all
    [[0], positives.lmap{|x| [x, -x]}.cons].cons
  end

end
