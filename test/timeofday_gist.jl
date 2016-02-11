
module TimeOfDay_tests


export
  millisInOneSecond,
  microsInOnSecond,
  nanosInOneSecond,
  nanosInOneMilli,
  nanosInOneMicro,
  secondsInOneMinute,
  secondsInOneHour,
  secondsInOneDay,
  nanosInOneMinute,
  nanosInOneHour,
  nanosInOneDay,
  TimeOfDay,
  NegativeTimeOfDayError


const millisInOneSecond = Int64(1e3)
const microsInOnSecond = Int64(1e6)
const nanosInOneSecond = Int64(1e9)
const nanosInOneMilli = Int64(1e6)
const nanosInOneMicro = Int64(1e3)
const secondsInOneMinute = Int64(60)
const secondsInOneHour = Int64(3600)
const secondsInOneDay = secondsInOneHour * Int64(24)
const nanosInOneMinute = nanosInOneSecond * secondsInOneMinute
const nanosInOneHour = nanosInOneSecond * secondsInOneHour
const nanosInOneDay = nanosInOneSecond * secondsInOneDay



type NegativeTimeOfDayError{T} <: Exception
  val::T
end

immutable TimeOfDay <: Number
  nanosSinceMidnight::Int64

  function TimeOfDay{T<:Number}(val::T)
    rv = round(Int64, val)
    if (rv < 0)
      throw(NegativeTimeOfDayError(val))
    end
    new(rv)
  end
end

function TimeOfDay(str::AbstractString)
  tmp = split(str,":")
  minutes = 0
  seconds = 0
  nanos = 0
  
  hours = parse(Int64, tmp[1])
  if length(tmp) > 1
    minutes = parse(Int64, tmp[2])
  end

  if length(tmp) > 2
    tmp2 = split(tmp[3], ".")
    seconds = parse(Int64, tmp2[1])
    if length(tmp2) > 1
      nanos = parse(Int64, rpad(tmp2[2],9,"0")[1:9])
    end
  end

  TimeOfDay(hours * nanosInOneHour + minutes * nanosInOneMinute + seconds * nanosInOneSecond + nanos)
end




function Base.string(timeOfDay::TimeOfDay)
  secsSinceMidnight, nanos = divrem(timeOfDay.nanosSinceMidnight, nanosInOneSecond)
  hours, hourrem = divrem(secsSinceMidnight, secondsInOneHour)
  minutes, seconds = divrem(hourrem, secondsInOneMinute)
  microseconds = div(nanos, millisInOneSecond)
  string(lpad(hours,2,"0"), ":", lpad(minutes,2,"0"), ":", lpad(seconds,2,"0"), ".", lpad(microseconds,6,"0"))
end
Base.print(io::IO, time::TimeOfDay) = print(io, string(time))
Base.show(io::IO, time::TimeOfDay) = print(io, string(time))


# define how numbers get promoted to TimeOfDay
Base.promote_rule{T<:Real}(::Type{TimeOfDay}, ::Type{T}) = TimeOfDay
Base.convert(::Type{TimeOfDay}, str::AbstractString) = TimeOfDay(str)
Base.convert(::Type{TimeOfDay}, x::Real) = TimeOfDay(x)
Base.convert{T<:Number}(::Type{T}, x::TimeOfDay) = T(x.nanosSinceMidnight)

# now for each op, we define the op between TimeOfDay's, then the generic "promote" version of the op will handle conversion
Base.typemin(::Type{TimeOfDay}) = TimeOfDay(0)
Base.typemax(::Type{TimeOfDay}) = TimeOfDay(typemax(Int64))

for op in (:<, :>, :(==), :<=, :>=, :(Base.isless))
  @eval $op(t1::TimeOfDay, t2::TimeOfDay) = $op(t1.nanosSinceMidnight, t2.nanosSinceMidnight)
end
for op in (:+, :-, :(Base.rem))
  @eval $op(t1::TimeOfDay, t2::TimeOfDay) = TimeOfDay($op(t1.nanosSinceMidnight, t2.nanosSinceMidnight))
end

# some helpers for creating ranges of the form "timestart:timestep:timestop"
Base.colon(start::TimeOfDay, step::TimeOfDay, stop::TimeOfDay) = map(TimeOfDay, start.nanosSinceMidnight : step.nanosSinceMidnight : stop.nanosSinceMidnight)
Base.colon(start::TimeOfDay, step::Number, stop::TimeOfDay) = colon(start, TimeOfDay(step), stop)

iszero(t::TimeOfDay) = t.nanosSinceMidnight == 0




using FactCheck

facts("TimeOfDay") do
  @fact TimeOfDay("10") => 10 * nanosInOneHour
  @fact TimeOfDay("10:30") => 10 * nanosInOneHour + 30 * nanosInOneMinute
  @fact TimeOfDay("10:30:05") => 10 * nanosInOneHour + 30 * nanosInOneMinute + 5 * nanosInOneSecond
  @fact TimeOfDay("10:30:05.00001") => 10 * nanosInOneHour + 30 * nanosInOneMinute + 5 * nanosInOneSecond + 10 * nanosInOneMicro

  t = TimeOfDay("10:30:05")
  buf = IOBuffer()
  print(buf, t)
  @fact bytestring(buf) => "10:30:05.000000"

  tdiff = TimeOfDay(nanosInOneMinute)
  trange = t : tdiff : t + 5 * nanosInOneMinute
  @fact length(trange) => 6
  @fact trange[2] => TimeOfDay("10:31:05")

  @fact iszero(TimeOfDay(0)) => true
  @fact iszero(TimeOfDay(1)) => false
  @fact_throws TimeOfDay(-1)
end

end # module
tod = TimeOfDay_tests