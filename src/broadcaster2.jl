
import FastAnonymous


# filter on (Nullable(v1), Nullable(v2))??

# # any Filters need to map a type to an index.  index 0 equates to "no filter"
# immutable Filter{T} end
# mapToIndex(f::Filter{UID}, val::UID) = Int(val)
# mapToIndex(f::Filter{Exchange}, val::Exchange) = Int(val.val)



# both a Router (broadcast side) and a Subscriber register interest with the HUB

# -----------------------------------------------------------------------

immutable Filterable{T}
  val::T
end

immutable FilterSet{T}
  vals::Set{Filterable{T}}
end
Filter{T}(vals::T...) = Filter(Set(map(Filterable,vals)))

immutable Filters
  d::Dict{Symbol,FilterSet}
end
Filters() = Filters(Dict{Symbol,Filter}())
Filters(filterpairs::Tuple{Symbol,Filter}...) = Filters(Dict(filterpairs...))
Filters(filterlists::Vector...) = Filters(map(x->(x[1],Filter(x[2:end]...)), filterlists)...)

# -----------------------------------------------------------------------

"""
broadcast should, as quickly as possible, map to subscribers methods for a given argument list.

lets try using a FastAnonymous @anon function, and swap out the args
  anonf = @anon args -> functionName(receivingObject, args...)


can we store the list of subscribers directly for a given filters/function pair?
maybe there should be "listening" and "broadcast" methods which register with the --- 


how about: @broadcast is a macro call at the code-site... the macro expands to: 
  register gensym-ed function with the BROADCASTER
  return direct function call on the 
"""


# -----------------------------------------------------------------------

# a Publisher is set up from the broadcast side
type Publisher
  f::Function
  anonfuns::Vector{FastAnonymous.Fun}
  filters::Filters
end
Publisher(f::Function, filters::Filters = Filters()) = register(Publisher(f, Any[], filters))


# call this to actually trigger the callbacks
function publish(publisher::Publisher, args...)
  for anonfun in publisher.anonfuns
    anonfun(args)
  end
end

# -----------------------------------------------------------------------


immutable Subscriber
  f::Function
  anonfun::FastAnonymous.Fun  # this is what's actually called
  filter::Filters  # TODO: do we need this here?
end

function subscribe(f::Function, listener, filters::Filters)
  # create a placeholder anonymous function, then swap out the 
  # function and listener before it gets compiled
  anonfun = FastAnonymous.@anon args -> tmpf(0, args...)
  anonfun.ast.args[2].args[1] = f
  anonfun.ast.args[2].args[2] = listener

  register(Subscriber(f, anonfun, filters))
end

# -----------------------------------------------------------------------

immutable Hub
  subscribers::Vector{Subscriber}
  publishers::Vector{Publisher}
end

const HUB = Hub(Subscriber[], Publisher[])

function register(subscriber::Subscriber)
  # add to subscribers list
  push!(HUB.subscribers, subscriber)

  # match subscriber filters to publisher's filters... add this subscriber's anonfun to matching publishers
  for publisher in HUB.publishers
    if matches(publisher, subscriber)
      push!(publisher.anonfuns, subscriber.anonfun)
    end
  end

  return
end

function register(publisher::Publisher)
  # add to publishers list
  push!(HUB.publishers, publisher)

  # match publisher's filters to subscriber's filters... add matching subscribers' anonfuns to publisher.
  for subscriber in HUB.subscribers
    if matches(publisher, subscriber)
      push!(publisher.anonfuns, subscriber.anonfun)
    end
  end

  return publisher
end


function matches(publisher::Publisher, subscriber::Subscriber)
  # return instantly if it's not the right function
  publisher.f == subscriber.f || return false

  # now lets evaluate the publisher's filters and, for each filter symbol, ensure the subscriber:
  #   1) doesn't have a filter for that symbol, or
  #   2) has a non-empty intersection between the filter sets for that symbol
  # if both are false, return false
  # TODO!!

  # if we got this far, return true
  return true
end
