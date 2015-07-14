
# allows for registering listeners that handle functions of the form:
#		somefunction(listener, args...)

# a function can be broadcast to all listeners using the form:
#		broadcastto(somefunction, (uid, exch), args...)

# to register a listener:
#		listenfor(somefunction, listener, vectorOfUIDsToFilter, vectorOfExchangesToFilter)


# Example:

# julia> callback(x, y) = println(x, " ", y)
#   callback (generic function with 1 method)
# julia> listenfor(callback, "someobject", [5,6])
# julia> listenfor(callback, "someotherobject", [6,7])
# julia> broadcastto(callback, 5, "payload")
#   someobject payload
# julia> broadcastto(callback, 6, "payload")
#   someobject payload
#   someotherobject payload
# julia> broadcastto(callback, 7, "payload")
#   someotherobject payload



##############################################
# matrix version
##############################################

type ListenerFilter
	# each vector in the matrix is a list of listeners for that (uid, exch) pair
	# note: the final row (maxuid+1) is for those listeners that don't filter on UID
	# note: the final col (NUMEXCH+1) is for those listeners that don't filter on exch
	# note: the bottom right corner (maxuid+1, NUMEXCH+1) is for listeners with no filter
	maxuid::Int
	filterMatrix::Matrix{Vector{Any}}
	nrows::Int
	ncols::Int

	function ListenerFilter(maxuid::Integer)
		nr = maxuid + 1
		nc = typemax(Exchange).val + 1
		a = Array(Vector{Any}, nr, nc)
		for r in 1:nr
			for c in 1:nc
				a[r,c] = Any[]
			end
		end
		new(maxuid, a, nr, nc)
	end
end

function addListener(lf::ListenerFilter, listener, items1::VecI = Int[], items2::VecI = Int[])
	rows = (length(items1) == 0 ? [lf.maxuid+1] :  items1)
	cols = (length(items2) == 0 ? [typemax(Exchange).val+1] : items2)
	for r in rows
		for c in cols
			# println("$r $c $rows $cols")
			push!(lf.filterMatrix[r,c], listener)
		end
	end
	# println("ADDED LISTENER: ", lf, " ", listener, " ", items1, " ", items2)
end




type Broadcaster
	maxuid::Int
	registry::Dict{Function, ListenerFilter}

	Broadcaster() = new()
	# Broadcaster(maxuid::Int) = new(maxuid, Dict{Function, ListenerFilter}())
end

Base.string(b::Broadcaster) = "Broadcaster{maxuid=$(b.maxuid), functions=$(keys(b.registry))}"
Base.print(io::IO, b::Broadcaster) = print(io, string(b))
Base.show(io::IO, b::Broadcaster) = print(io, string(b))




# set up a const global (singleton) BROADCASTER
const BROADCASTER = Broadcaster()

function initBroadcaster(maxuid::Integer)
	BROADCASTER.maxuid = maxuid
	BROADCASTER.registry = Dict{Function, ListenerFilter}()
end


# function listen(bc::Broadcaster, f::Function, listener, items1::Vector{UID} = UID[], items2::Vector{Exchange} = Exchange[])
function listenfor(f::Function, listener, items1::Vector{UID} = UID[], items2::Vector{Exchange} = Exchange[])
	DEBUG("listenfor: $f $listener")
	lf = get!(BROADCASTER.registry, f, ListenerFilter(BROADCASTER.maxuid))
	addListener(lf, listener, round(Int, items1), [Int(exch.val) for exch in items2])
end


listenfor(f::Function, listener, uid::UID) = listenfor(f, listener, [uid])
listenfor(f::Function, listener, exch::Exchange) = listenfor(f, listener, UID[], [exch])
listenfor(f::Function, listener, uid::UID, exch::Exchange) = listenfor(f, listener, [uid], [exch])



# call this function in order to call function "f" for all listeners, with that listener as the first arg
# note we can set UID to 0, or Exchange to NONE, and it will not filter on that.
#		this allows us the flexibility to send/listen to exchange-only messages, or symbol-only messages

# function broadcastto(bc::Broadcaster, f::Function, vals::Tuple{UID, Exchange}, args...)
function broadcastto(f::Function, vals::Tuple{UID, Exchange}, args...)
	if !haskey(BROADCASTER.registry, f)
		return
	end
	
	lf = BROADCASTER.registry[f]
	r = Int(vals[1])
	c = Int(vals[2])
	
	for listener in lf.filterMatrix[lf.nrows, lf.ncols]  # no filter
		f(listener, args...)
	end

	if r != 0
		for listener in lf.filterMatrix[r, lf.ncols] # filter on UID
			f(listener, args...)
		end
	end
	
	if c != 0
		for listener in lf.filterMatrix[lf.nrows, c] # filter on Exchange
			f(listener, args...)
		end
	end

	if r != 0 && c != 0
		for listener in lf.filterMatrix[r, c] # filter on both
			f(listener, args...)
		end
	end
end

