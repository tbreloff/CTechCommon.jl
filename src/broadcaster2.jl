
import FastAnonymous: @anon


# filter on (Nullable(v1), Nullable(v2))??

# any Filters need to map a type to an index.  index 0 equates to "no filter"
immutable Filter{T} end
mapToIndex(f::Filter{UID}, val::UID) = Int(val)
mapToIndex(f::Filter{Exchange}, val::Exchange) = Int(val.val)

# function addListener


"""
broadcast should, as quickly as possible, map to listeners methods for a given argument list.

lets try using a FastAnonymous @anon function, and swap out the args
  anonf = @anon args -> functionName(receivingObject, args...)
"""


type Listener




# NOTE: getlisteners(fname, filter) should return an iterator!!!!
function broadcastto(functionName::Symbol, filter::Filter, args...)
  for listener in getlisteners(functionName, filter)
    listener.anonFunction(args)
  end
end