

"""
Implements a pub-sub model, where you can subscribe to a feed with an optional set of filters
and get only those callbacks where all your filterset overlaps with the matching filterset 
of the publisher.  Once registered, filters are fixed.  You must unregister and then register
again to update filters.

# this will set up and register a publisher which matches subscribers listening for UID(1) and EDGX
# and also subscribers that don't filter on those filterkeys
pub = Publisher(somefunction, Filters([:uid, UID(1)], [:exch, EDGX]))

# this subscribes the receiving object on all callbacks to somefunction.  the callbacks will occur
# whenever there is a publish command on somefunction with uid filter that includes either UID(1) or UID(2)
sub = subscribe(somefunction, recvObject, Filters([:uid, UID(1), UID(2)]))

# this generates all the callbacks for connected listeners, effectively calling:
#     somefunction(recvObject, args...)
# for each connected subscriber
publish(pub, args...)

# done listening...
unregister(sub)

# done publishing
unregister(pub)

"""

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

typealias FilterSet Set{Any}
typealias FilterMap Dict{Symbol,FilterSet}

immutable Filters
  d::FilterMap
end
Filters() = Filters(FilterMap())
Filters(filterlists::Vector...) = Filters(FilterMap(map(x -> (Symbol(x[1]), FilterSet(x[2:end])), filterlists)))

# -----------------------------------------------------------------------

# a Publisher is set up from the broadcast side
type Publisher{F<:Function}
  f::F
  listeners::Vector{Any}
  filters::Filters
end
Publisher(f::Function, filters::Filters = Filters()) = register(Publisher(f, Any[], filters))

Base.isempty(publisher::Publisher) = isempty(publisher.listeners)

# call this to actually trigger the callbacks
function publish(publisher::Publisher, args...)
    for listener in publisher.listeners
        publisher.f(listener, args...)
    end
end

# -----------------------------------------------------------------------


immutable Subscriber{F<:Function,L}
  f::F
  listener::L
  filters::Filters
end

# call this to start listening
function subscribe(f::Function, listener, filters::Filters = Filters())
  register(Subscriber(f, listener, filters))
end

# -----------------------------------------------------------------------

"""
A wrapper to schedule method calls for the future.  For example, a minute timer:

```
    cb = Callback(calculate, my_obj)
    schedule(TimeOfDay("9:31") : TimeOfDay("00:01") : stopTime, cb)
```

This example will call `calculate(my_obj)` once per minute in the simulation.
"""
immutable Callback
    pub::Publisher
    subs::Vector{Subscriber}
end

function Callback(f::Function, objs...)
    filters = Filters(vcat(:obj, objs))
    subs = [subscribe(f, obj, filters) for obj in objs]
    pub = Publisher(f, filters)
    Callback(pub, subs)
end

# function Callback(f::Function, args...)
#     obj = args[1]
#     filters = Filters(vcat(:obj, obj))
#     subs = [subscribe(f, obj, filters) for obj in args]
#     pub = Publisher(f, filters)
#     Callback(pub, subs)
# end

publish(cb::Callback, args...) = publish(cb.pub, args...)

# # subscribe ourselves
# filter = Filters([:obj, top])
# subscribe(calculate, top, filter)

# # set up a timer with the same callback function and filter (I'll wrap this functionality eventually)
# timer = Publisher(calculate, filter)
# schedule(TimeOfDay("9:31") : TimeOfDay("00:01") : stopTime, timer)


# -----------------------------------------------------------------------

immutable Hub
  subscribers::Set{Subscriber}
  publishers::Set{Publisher}
end

const HUB = Hub(Set{Subscriber}(), Set{Publisher}())

function reset_hub()
  for publisher in HUB.publishers
    empty!(publisher.listeners)
  end
  empty!(HUB.publishers)
  empty!(HUB.subscribers)
end

function register(subscriber::Subscriber)
  # add to subscribers list
  push!(HUB.subscribers, subscriber)

  # match subscriber filters to publisher's filters... add this subscriber's listener to matching publishers
  for publisher in HUB.publishers
    if matches(publisher, subscriber)
      push!(publisher.listeners, subscriber.listener)
    end
  end

  subscriber
end

function unregister(subscriber::Subscriber)
  delete!(HUB.subscribers, subscriber)

  for publisher in HUB.publishers

    # TODO: this should be a simple "delete!" call, but doesn't work for vectors
    delidx = 0
    for (i,listener) in enumerate(publisher.listeners)
      if listener === subscriber.listener
        delidx = i
        break
      end
    end
    if delidx > 0
      deleteat!(publisher.listeners, delidx)
    end
  end
end



function register(publisher::Publisher)
  # add to publishers list
  push!(HUB.publishers, publisher)

  # match publisher's filters to subscriber's filters... add matching subscribers' anonfuns to publisher.
  for subscriber in HUB.subscribers
    if matches(publisher, subscriber)
      push!(publisher.listeners, subscriber.listener)
    end
  end

  publisher
end

function unregister(publisher::Publisher)
  delete!(HUB.publishers, publisher)
end



function matches(publisher::Publisher, subscriber::Subscriber)
  # return instantly if it's not the right function
  publisher.f == subscriber.f || return false

  # now lets evaluate the publisher's filters and, for each filter symbol, ensure the subscriber:
  #   1) doesn't have a filter for that symbol, or
  #   2) has a non-empty intersection between the filter sets for that symbol
  # if both are false, return false
  for (filterkey, pubset) in publisher.filters.d
    if haskey(subscriber.filters.d, filterkey)
      # both sub and pub have this filter key... if the values don't overlap then there's no match
      subscriberset = subscriber.filters.d[filterkey]
      isempty(intersect(pubset, subscriberset)) && return false
    end
  end

  # if we got this far, return true
  return true
end
