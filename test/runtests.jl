using CTechCommon
# using FactCheck
using Base.Test

# @testset "all" begin

# @testset "arrays" begin
#   r = 1:10
#   x = collect(r)
#   @test get(getith(r,3)) == 3
#   @test get(getith(x,3)) == 3
#   @test isnull(getith(x,11)) == true

#   z = ([1,"one"], [2,"two"])
#   z1, z2 = unzip(z)
#   @test z1 == [1,2]
#   @test z2 == ["one","two"]
#   @test sizes(z) == ((2,),(2,))
#   @test mapf((sin,cos), 1) == [sin(1), cos(1)]

#   m = rand(3,3)
#   v = rand(3)
#   @test row(m, 1)[2] == m[1,2]
#   @test col(m, 1)[2] == m[2,1]
#   vw = rows(m, 1:2)
#   vw[1,1] = 0
#   @test m[1,1] == 0
#   @test nrows(m) == 3
#   @test ncols(m) == 3
#   @test nrows(v) == 3
#   @test ncols(v) == 1

#   m = reshape(collect(1:4),2,2)
#   @test addOnes(collect(1:3)) == Int[1,2,3,1]
#   @test addOnes(collect(1:3.)) == Float64[1,2,3,1]
#   @test addOnes(m) == Int[1 3 1; 2 4 1]

#   @test getPctOfInt(0.5, 10) == 5
#   @test getPctOfInt(1.5, 10) == 10
#   @test splitRange(10, 0.5) == (1:5, 6:10)
#   @test splitMatrixRows(m, 0.5)[1] == rows(m, 1:1)

#   @test stringfloat(0.1111) == "0.111"
#   @test stringfloat(0.1111, 1) == "0.1"
#   @test stringfloats([0.1111, 0.9999], 2) == "[0.11, 1.00]"
# end


# facts("misc") do
#   @test donothing(5,5) == nothing
#   @test nop(5) == 5
#   @test returntrue(5) == true
# end


@testset "price" begin
  @test Price(50.55) == CTechCommon.makePrice(5055, 2)
  @test Price(50.55, 4) == Price(50.55, 2)

  fp = 55.55555
  p = Price(fp)
  @test p.priceLong == 555556
  @test p.precision == 4
  @test p.multiplier == 10_000
  @test CTechCommon.getLong(p, 2) == 5556
  @test float(p + Price(1.01,2)) ≈ 56.5656

  p = Price(fp, 2)
  rounded = round(fp, 2)
  @test p + 0.001 == p
  @test float(p + 0.005) ≈ rounded + 0.01
  @test float(p * 2) ≈ rounded * 2
end


@testset "time" begin
  # function jacob_calcSecondsEpochToMidnight(secondsSinceEpoch::Integer)
  #   utc = DateTime(Date(Dates.unix2datetime(secondsSinceEpoch)))
  #   adjustment = Dates.Second(div(Dates.value(now() - now(Dates.UTC)),1000))
  #   return Dates.value(utc+adjustment)
  # end

  year, month, day = 2013,1,1
  @test CTechCommon.getHoursAdjustmentFromUTC(year,month,day) == 5

  @test TimeOfDay("10") == 10 * nanosInOneHour
  @test TimeOfDay("10:30") == 10 * nanosInOneHour + 30 * nanosInOneMinute
  @test TimeOfDay("10:30:05") == 10 * nanosInOneHour + 30 * nanosInOneMinute + 5 * nanosInOneSecond
  @test TimeOfDay("10:30:05.00001") == 10 * nanosInOneHour + 30 * nanosInOneMinute + 5 * nanosInOneSecond + 10 * nanosInOneMicro

  t = TimeOfDay("10:30:05")
  buf = IOBuffer()
  print(buf, t)
  @test String(buf) == "10:30:05.000000"

  tdiff = TimeOfDay(nanosInOneMinute)
  trange = t : tdiff : t + 5 * nanosInOneMinute
  @test length(trange) == 6
  @test trange[2] == TimeOfDay("10:31:05")

  @test iszero(TimeOfDay(0)) == true
  @test iszero(TimeOfDay(1)) == false
  @test_throws CTechCommon.NegativeTimeOfDayError{Int64} TimeOfDay(-1)

end


@testset "fixedsym" begin
  str = "abc"

  n = 6
  buf = IOBuffer(n)
  for c in str
    write(buf, UInt8(c))
  end
  for i in buf.size+1:n
    write(buf, UInt8(0))
  end

  buf.ptr = 1
  sym = Symbol6(buf)
  @test sizeof(sym) == n
  @test String(sym) == str

  n = 8
  buf = IOBuffer(n)
  for c in str
    write(buf, UInt8(c))
  end
  for i in buf.size+1:n
    write(buf, UInt8(0))
  end

  buf.ptr = 1
  sym = Symbol8(buf)
  @test sizeof(sym) == n
  @test String(sym) == str
end


@testset "bufferedio" begin
end


@testset "trie" begin
end


@testset "Logger" begin
  @test log_severity() == InfoSeverity
  f = open(tempname(),"w")
  @test log_io!(f) == nothing
  @test log_io() == f
  close(f)
  log_severity!(DebugSeverity)
  @test log_severity() == DebugSeverity
  log_severity!(ErrorSeverity)
  @test log_severity() == ErrorSeverity
  log_severity!(InfoSeverity)
end


@testset "markets" begin
  @test typeof(getFee(EDGX, false)) == Float64
  # @test EDGA < EDGX
  @test EXCH_SORTED_BY_TAKE_FEE == [EDGA,EDGX]

  id = generateOID()
  @test generateOID() == id + 1
  @test generateOID() == id + 2

  s = "MSFT"
  @test String(Ticker(s)) == s
  @test Ticker(s) == s
  @test Ticker(s) < "NSFT"
end

type TmpVal; val::Int; end
updatetmp(tmpval::TmpVal, newval::Integer) = (tmpval.val = newval; nothing)



type Counter
  n::Int
  Counter() = new(0)
end

@testset "pubsub" begin
  # TODO test: 
  #   various filters
  #   ordering of connections
  #   function types, argument lists
  #   unregistering

  # simple test function to add the sum of the args to the counter
  handlemsg(c::Counter, args...) = (c.n += sum(args))
  
  reset_hub()
  pub1 = Publisher(handlemsg, Filters([:key1, 5, 6], [:key2, "hi", "yo"]))

  c1 = Counter()
  sub1 = subscribe(handlemsg, c1)

  # sub1 should add 1 to c1
  publish(pub1, 1)
  @test c1.n == 1

  # now both sub1 and sub2 should be subscribed to pub1, so this should add 9 (2+3+4) twice
  sub2 = subscribe(handlemsg, c1, Filters([:key1, 6, 7, 8]))
  publish(pub1, 2,3,4)
  @test c1.n == 19

  # unregistering sub1, so the next pub should add 10 once
  unregister(sub1)
  publish(pub1, 5,5)
  @test c1.n == 29

  # sub3 should not be subscribed to pub1
  sub3 = subscribe(handlemsg, c1, Filters([:key2, "word"]))
  publish(pub1, 10)
  @test c1.n == 39

end


const tdiff = TimeOfDay("00:00:30")
const tstart = TimeOfDay("9:35:30")
const tstop = TimeOfDay("9:39:15")

@testset "scheduler" begin

  function periodiccallback(c, x...)
    c.n += sum(x)
    @LOG c x
    if c.n == 11
      stopScheduler(TimeOfDay("9:39:15"))
      LOG("stopScheduler")
    end
    schedule(NOW() + tdiff, pub, 2)
  end

  # set up a simple pub/sub, where the listener object is a Counter.
  # every time the event triggers, it reschedules tdiff (30 seconds) ahead.
  # the first pub at tstart has 1 as the arg, the rest have 2.
  # counter should reach 11 on the 6th pub at 9:38, at which time it schedules
  # the stop for tstop.
  # 2 more callbacks are scheduled and run before we hit the stop event at 9:39:15
  reset_hub()
  c = Counter()
  pub = Publisher(periodiccallback)
  sub = subscribe(periodiccallback, c)

  initScheduler()               # resets the scheduler (unnecessary for first pass)
  schedule(tstart, pub, 1)      # schedules first pub
  stopped = processAllEvents()  # main loop

  @test stopped == true
  @test NOW() == tstop
  @test c.n == 15
end

# end # all

# FactCheck.exitstatus()