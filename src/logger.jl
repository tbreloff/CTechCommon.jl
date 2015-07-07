

# function printlnWithSpaces(io::IO, args...)
#   for a in args
#     print(io, a, ' ')
#   end
#   println()
# end
# LOG(io::IO, args...) = (print(io, NOW(), ": "); printlnWithSpaces(io, args...))
# LOG(args...) = LOG(STDOUT, args...)




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

const DEBUG = LogSeverity(0)
const INFO = LogSeverity(1)
const ERROR = LogSeverity(2)


Base.string(sev::LogSeverity) = (sev == DEBUG ? "DEBUG" : (sev == INFO ? "INFO" : "ERROR"))
Base.print(io::IO, sev::LogSeverity) = print(io, string(sev))
Base.show(io::IO, sev::LogSeverity) = print(io, string(sev))

type SevObj
	sev::LogSeverity
end

const LOG_SEVERITY = SevObj(INFO)

log_severity() = LOG_SEVERITY.sev
log_severity(sev::LogSeverity) = (LOG_SEVERITY.sev = sev)

Base.isless(sev1::LogSeverity, sev2::LogSeverity) = sev1.val < sev2.val

# --------------------------------------------------------

LOG(args...) = LOG(INFO, args...)

function LOG(sev::LogSeverity, args...)
	if sev >= log_severity()
		println("$(NOW()) [$sev]: ", join(vcat(map(string,args)..., backtracestring()), " "))
		# println(string(log_severity()), ": ", join(vcat(map(string,args)..., backtracestring()), " "))
	end
end


# default to INFO
macro LOG(symbols...)
	# sev = INFO
	# if sev < log_severity()
	# 	return
	# end

  expr = :(LOG())
  for s in symbols
    push!(expr.args, "$s:")
    push!(expr.args, esc(s))
  end
  expr
end

macro ERROR(symbols...)
  expr = :(LOG(ERROR))
  for s in symbols
    push!(expr.args, "$s:")
    push!(expr.args, esc(s))
  end
  expr
end

macro DEBUG(symbols...)
	# if DEBUG < log_severity()
	# 	return
	# end

  expr = :(LOG(DEBUG))
  for s in symbols
    push!(expr.args, "$s:")
    push!(expr.args, esc(s))
  end
  expr
end


#------------------------------------------------------- Simple tests/examples 

testbtstring() = LOG("Hello","world")
function testbtstring2()
	i,j = 2, 23432.23423
	@LOG(i, j)
end

