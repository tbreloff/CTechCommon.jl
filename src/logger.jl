
backtrace_list() = [ccall(:jl_lookup_code_address, Any, (Ptr{Void}, Int32), b, 0) for b in backtrace()]

function backtracestring()

	# get the backtrace and find the position of the "backtracestring()" call
	btlist = backtrace_list()
	btpos = find(x->x[1] == :backtracestring, btlist)[1]

	# find the first non-LOG, non-julia method and return that string
	for i in btpos+1:length(btlist)

		# skip julia internals and LOG calls
		methodname, pathname, filenum, tmp1, tmp2 = map(string, btlist[i])
		if methodname == "LOG" || methodname[1:3] == "jl_"
			continue
		end

		# get the filename from the full path, then return the string
		filename = split(pathname, "/")[end]
		return "[$filename:$filenum]"
	end
	"[]"
end




# --------------------------------------------------------


immutable LogSeverity
	val::Int
end

const Debug = LogSeverity(0)
const Info = LogSeverity(1)
const Error = LogSeverity(2)


Base.string(sev::LogSeverity) = (sev == Debug ? "Debug" : (sev == Info ? "Info" : "Error"))
Base.print(io::IO, sev::LogSeverity) = print(io, string(sev))
Base.show(io::IO, sev::LogSeverity) = print(io, string(sev))
Base.isless(sev1::LogSeverity, sev2::LogSeverity) = sev1.val < sev2.val

# --------------------------------------------------------

type SevObj
	sev::LogSeverity
  io::IO
end

const LOG_SEVERITY = SevObj(Info, STDOUT)

log_severity() = LOG_SEVERITY.sev
log_severity!(sev::LogSeverity) = (LOG_SEVERITY.sev = sev; nothing)

log_io() = LOG_SEVERITY.io
log_io!(io::IO) = (LOG_SEVERITY.io = io; nothing)


# --------------------------------------------------------

LOG(args...) = LOG(Info, args...)
DEBUG(args...) = LOG(Debug, args...)
ERROR(args...) = LOG(Error, args...)

function LOG(sev::LogSeverity, args...)
	if sev >= log_severity()
    io = log_io()
		print(io, "$(NOW()) [$sev]: ")
    for arg in args
      print(io, arg, " ")
    end
    println(io, backtracestring())
      # join(vcat(map(string,args)..., backtracestring()), " "))
	end
end

# note: the macro version give "x: xval" for "@LOG x"

# default to Info
macro LOG(symbols...)
  expr = :(LOG(Info))
  for s in symbols
    push!(expr.args, "$s:")
    push!(expr.args, esc(s))
  end
  expr
end

macro ERROR(symbols...)
  expr = :(LOG(Error))
  for s in symbols
    push!(expr.args, "$s:")
    push!(expr.args, esc(s))
  end
  expr
end

macro DEBUG(symbols...)
  expr = :(LOG(Debug))
  for s in symbols
    push!(expr.args, "$s:")
    push!(expr.args, esc(s))
  end
  expr
end



