module BitmaskMethods
  # This helper will return an array of all of the bitmasks that 'x' can fall into.
  # A set with a max value of 4: [1,2,3,4] would be translated into 'bits' as [1,2,4,8]
  # according to the formula (2 ** (i-1)).
  #
  # The number 1 can appear in the following masks: [1, 3, 5, 7, 9, 11, 13, 15]
  #
  def possible_masks(x, max)
    bits = []
    (1..max).each do |i|
      bits << 2 ** (i-1)
    end
    bits.delete x
    mask = []
    mask << x
    bits.each do |b|
      mask << x + b
    end
    while bits.length > 0
      mask.each do |m|
        bits.each do |b|
          mask << m + b if b > m
        end
      end
      bits.shift
    end
    mask = mask.uniq.sort
    mask
  end
end