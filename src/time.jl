
const millisInOneSecond   = Int(1e3)
const microsInOnSecond    = Int(1e6)
const nanosInOneSecond    = Int(1e9)
const nanosInOneMilli     = Int(1e6)
const nanosInOneMicro     = Int(1e3)
const secondsInOneMinute  = Int(60)
const secondsInOneHour    = Int(3600)
const secondsInOneDay     = secondsInOneHour * Int(24)
const nanosInOneMinute    = nanosInOneSecond * secondsInOneMinute
const nanosInOneHour      = nanosInOneSecond * secondsInOneHour
const nanosInOneDay       = nanosInOneSecond * secondsInOneDay

const _epoch_millis = UInt64(DateTime(1970,1,1).instant.periods.value)
const _est5edt = TimeZone("EST5EDT")


function currentTimeOfDay()
  n = now()
  h = Dates.hour(n)
  m = Dates.minute(n)
  s = Dates.second(n)
  TimeOfDay(h * nanosInOneHour + m * nanosInOneMinute + s * nanosInOneSecond)
end


calcSecondsSinceMidnight(hour::Int, minute::Int) = hour * secondsInOneHour + secondsInOneMinute


# NOTE: DateTime module does NOT have timezone info, so all those calls are UTC

function getHoursAdjustmentFromUTC(year::Integer, month::Integer, day::Integer; timezone = _est5edt)
  # create a historically-aware timezone-aware datetime
  dt = ZonedDateTime(DateTime(year,month,day), timezone)

  # extract the hours offset from UTC
  round(Int, -TimeZones.value(dt.zone.offset) / 3600)
end


createUTCDateTimeFromSecondsSinceEpoch(secondsSinceEpoch::Integer) = DateTime(Dates.UTM(secondsSinceEpoch * millisInOneSecond + _epoch_millis))

function calcSecondsEpochToMidnight(secondsSinceEpoch::Integer)

  dt = createUTCDateTimeFromSecondsSinceEpoch(secondsSinceEpoch)

  # get the hour adjustment
  y = Dates.year(dt)
  m = Dates.month(dt)
  d = Dates.day(dt)
  hourAdjustment = getHoursAdjustmentFromUTC(y, m, d)

  millisMidnightUTC = UInt64(DateTime(y, m, d).instant.periods.value)
  millisMidnightEST = UInt64(millisMidnightUTC + hourAdjustment * secondsInOneHour * millisInOneSecond)

  return round(UInt64, (millisMidnightEST - _epoch_millis) / millisInOneSecond)
end

function convertSecondsSinceEpochToSecondsSinceMidnight(secondsSinceEpoch::Integer)
  secondsSinceEpoch - calcSecondsEpochToMidnight(secondsSinceEpoch)
end


#############################################
# TimeOfDay
#############################################

type NegativeTimeOfDayError{T} <: Exception
  val::T
end

immutable TimeOfDay <: Number
  nanosSinceMidnight::Int

  function TimeOfDay{T<:Number}(val::T)
    if (val < zero(T))
      throw(NegativeTimeOfDayError{T}(val))
      # error("TimeOfDay constructor is negative! $val")
    end
    new(round(Int, val))
  end
end

function TimeOfDay(str::AbstractString)
  tmp = split(str,":")
  minutes = 0
  seconds = 0
  nanos = 0
  
  hours = parse(Int, tmp[1])
  if length(tmp) > 1
    minutes = parse(Int, tmp[2])
  end

  if length(tmp) > 2
    tmp2 = split(tmp[3], ".")
    seconds = parse(Int, tmp2[1])
    if length(tmp2) > 1
      nanos = parse(Int, rpad(tmp2[2],9,"0")[1:9])
    end
  end

  TimeOfDay(hours * nanosInOneHour + minutes * nanosInOneMinute + seconds * nanosInOneSecond + nanos)
end

Base.convert(::Type{TimeOfDay}, str::AbstractString) = TimeOfDay(str)

Base.typemin(::Type{TimeOfDay}) = TimeOfDay(0)
Base.typemax(::Type{TimeOfDay}) = TimeOfDay(nanosInOneDay)

function hmsu(t::TimeOfDay)
    secsSinceMidnight, nanos = divrem(t.nanosSinceMidnight, nanosInOneSecond)
    hours, hourrem = divrem(secsSinceMidnight, secondsInOneHour)
    minutes, seconds = divrem(hourrem, secondsInOneMinute)
    microseconds = div(nanos, millisInOneSecond)
    hours, minutes, seconds, microseconds
end

function Base.show(io::IO, t::TimeOfDay)
    # hours, minutes, seconds, microseconds = hmsu(t)
    @printf(io,"%d:%02d:%02d.%06d",hmsu(t)...)
    # print(io, lpad(hours,2,"0"), ":", lpad(minutes,2,"0"), ":", lpad(seconds,2,"0"), ".", lpad(microseconds,6,"0"))
end
# @createIOMethods TimeOfDay

# define how numbers get promoted to TimeOfDay
Base.promote_rule{T<:Integer}(::Type{TimeOfDay}, ::Type{T}) = TimeOfDay
Base.promote_rule{T<:AbstractFloat}(::Type{TimeOfDay}, ::Type{T}) = TimeOfDay
Base.convert{T<:Integer}(::Type{TimeOfDay}, x::T) = TimeOfDay(x)
Base.convert{T<:AbstractFloat}(::Type{TimeOfDay}, x::T) = TimeOfDay(x)
Base.convert{T<:Number}(::Type{T}, x::TimeOfDay) = T(x.nanosSinceMidnight)

# now for each op, we define the op between TimeOfDay's, then the generic "promote" version of the op will handle conversion

# for op in (:(Base.typemax), :(Base.typemin))
#   @eval $op(::Type{TimeOfDay}) = TimeOfDay($op(Int64))
# end
for op in (:<, :>, :(==), :<=, :>=, :(Base.isless))
  @eval $op(t1::TimeOfDay, t2::TimeOfDay) = $op(t1.nanosSinceMidnight, t2.nanosSinceMidnight)
end
for op in (:+, :-, :(Base.rem))
  @eval $op(t1::TimeOfDay, t2::TimeOfDay) = TimeOfDay($op(t1.nanosSinceMidnight, t2.nanosSinceMidnight))
end

# some helpers for creating ranges of the form "timestart:timestep:timestop"
Base.colon(start::TimeOfDay, step::TimeOfDay, stop::TimeOfDay) = map(TimeOfDay, start.nanosSinceMidnight : step.nanosSinceMidnight : stop.nanosSinceMidnight)
Base.colon{T<:Number}(start::TimeOfDay, step::T, stop::TimeOfDay) = colon(start, TimeOfDay(step), stop)

iszero(t::TimeOfDay) = t.nanosSinceMidnight == 0

function timeofday_formatter(hrs::Number)
    h,m,s,u = hmsu(TimeOfDay(hrs * nanosInOneHour))
    @sprintf("%d:%02d:%02d",h,m,s)
end

hours(t::TimeOfDay) = Float64(t) / nanosInOneHour

@recipe f{T<:AbstractVector{TimeOfDay}}(::Type{T}, a::T) = (xformatter := timeofday_formatter; map(hours, a))
@recipe f{T<:AbstractMatrix{TimeOfDay}}(::Type{T}, a::T) = (xformatter := timeofday_formatter; map(hours, a))
