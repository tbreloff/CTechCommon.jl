
const millisInOneSecond = Int(1e3)
const microsInOnSecond = Int(1e6)
const nanosInOneSecond = Int(1e9)
const nanosInOneMilli = Int(1e6)
const nanosInOneMicro = Int(1e3)
const secondsInOneMinute = Int(60)
const secondsInOneHour = Int(3600)
const secondsInOneDay = secondsInOneHour * Int(24)
const nanosInOneMinute = nanosInOneSecond * secondsInOneMinute
const nanosInOneHour = nanosInOneSecond * secondsInOneHour
const nanosInOneDay = nanosInOneSecond * secondsInOneDay


# NOTE: this might be overridden for simulations
NOW() = TimeOfDay("0")


calcSecondsSinceMidnight(hour::Int, minute::Int) = hour * secondsInOneHour + secondsInOneMinute


# NOTE: DateTime module does NOT have timezone info, so all those calls are UTC
# NOTE: Calendar module does timezone calc... parse_date is WRONG, which is why i'm using ymd

function getHoursAdjustmentFromUTC(year::Integer, month::Integer, day::Integer)
  millisEST = Calendar.ymd(year, month, day, "EST5EDT").millis
  millisUTC = Calendar.ymd(year, month, day, "UTC").millis
  UInt64(round((millisEST - millisUTC) / (secondsInOneHour * millisInOneSecond)))
end


getEpochMillis() = UInt64(DateTime(1970,1,1).instant.periods.value)
createUTCDateTimeFromSecondsSinceEpoch(secondsSinceEpoch::Integer) = DateTime(Dates.UTM(secondsSinceEpoch * millisInOneSecond + getEpochMillis()))

function calcSecondsEpochToMidnight(secondsSinceEpoch::Integer)

  dt = createUTCDateTimeFromSecondsSinceEpoch(secondsSinceEpoch)

  # get the hour adjustment using the Calendar module
  y = Dates.year(dt)
  m = Dates.month(dt)
  d = Dates.day(dt)
  hourAdjustment = getHoursAdjustmentFromUTC(y, m, d)

  millisMidnightUTC::UInt64 = DateTime(y, m, d).instant.periods.value
  millisMidnightEST::UInt64 = millisMidnightUTC + hourAdjustment * secondsInOneHour * millisInOneSecond

  return UInt64((millisMidnightEST - getEpochMillis()) / millisInOneSecond)
end


# assuming we are given # seconds since UTC epoch, convert that to # seconds since midnight for US/Eastern timezone
function convertSecondsSinceEpochToSecondsSinceMidnight(secondsSinceEpoch::Integer)

  dt = createUTCDateTimeFromSecondsSinceEpoch(secondsSinceEpoch)

  # get the hour adjustment using the Calendar module
  y = Dates.year(dt)
  m = Dates.month(dt)
  d = Dates.day(dt)
  hourAdjustment = getHoursAdjustmentFromUTC(y, m, d)

  # get a datetime for midnight
  dtMidnightMillis::UInt64 = DateTime(y, m, d).instant.periods.value

  # now subtract the diff in UTC at midnight vs UTC now, then subtract the timezone adjustment
  secondsSinceMidnight = (dt.instant.periods.value - dtMidnightMillis) / millisInOneSecond - hourAdjustment * secondsInOneHour
  return UInt64(secondsSinceMidnight)
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
    new(max(0, round(Int, val)))
  end
end

function TimeOfDay(str::String)
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

Base.convert(::Type{TimeOfDay}, str::String) = TimeOfDay(str)



function Base.string(timeOfDay::TimeOfDay)
  secsSinceMidnight, nanos = divrem(timeOfDay.nanosSinceMidnight, nanosInOneSecond)
  hours, hourrem = divrem(secsSinceMidnight, secondsInOneHour)
  minutes, seconds = divrem(hourrem, secondsInOneMinute)
  microseconds = div(nanos, millisInOneSecond)
  string(lpad(hours,2,"0"), ":", lpad(minutes,2,"0"), ":", lpad(seconds,2,"0"), ".", lpad(microseconds,6,"0"))
end
@createIOMethods TimeOfDay

# define how numbers get promoted to TimeOfDay
Base.promote_rule{T<:Integer}(::Type{TimeOfDay}, ::Type{T}) = TimeOfDay
Base.promote_rule{T<:FloatingPoint}(::Type{TimeOfDay}, ::Type{T}) = TimeOfDay
Base.convert{T<:Integer}(::Type{TimeOfDay}, x::T) = TimeOfDay(x)
Base.convert{T<:FloatingPoint}(::Type{TimeOfDay}, x::T) = TimeOfDay(x)
Base.convert{T<:Number}(::Type{T}, x::TimeOfDay) = T(x.nanosSinceMidnight)

# now for each op, we define the op between TimeOfDay's, then the generic "promote" version of the op will handle conversion

for op in (:(Base.typemax), :(Base.typemin))
  @eval $op(::Type{TimeOfDay}) = TimeOfDay($op(Int64))
end
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
