-- bit() return the value of a bit, given the
-- position (p) of that bit.  p must be a positive
-- non-zero integer
function bit(p)
  return 2 ^ (p - 1)  -- 1-based indexing
end

-- hasbit() returns a boolean telling whether or
-- not a particular bit is set in a number.
-- both arguments to hasbit should be numeric
-- integers.
-- Typical call:  if hasbit(x, bit(3)) then ...
function hasbit(x, p)
  return x % (p + p) >= p       
end

-- returns the value of a number if a particular
-- bit in that number were forced on.  If the bit
-- is already on in that number, the number is
-- unchanged.
function setbit(x, p)
  return hasbit(x, p) and x or x + p
end

-- returns the value of a number if a particular
-- bit in that number were forced off.  If the bit
-- is already off in that number, the number is
-- unchanged.
function clearbit(x, p)
  return hasbit(x, p) and x - p or x
end

-- returns the value of a number if a particular
-- bit in that number were toggld.
function flipbit(x, p)
  return hasbit(x,p) and x - p or x + p
end