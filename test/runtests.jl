using CTechCommon
using FactCheck


facts("arrays") do
  r = 1:10
  x = collect(r)
  @fact get(getith(r,3)) => 3
  @fact get(getith(x,3)) => 3
  @fact isnull(getith(x,11)) => true

  z = ([1,"one"], [2,"two"])
  z1, z2 = unzip(z)
  @fact z1 => [1,2]
  @fact z2 => ["one","two"]
  @fact sizes(z) => ((2,),(2,))
  @fact mapf((sin,cos), 1) => [sin(1), cos(1)]

  m = rand(3,3)
  v = rand(3)
  @fact row(m, 1)[2] => m[1,2]
  @fact col(m, 1)[2] => m[2,1]
  vw = rows(m, 1:2)
  vw[1,1] = 0
  @fact m[1,1] => 0
  @fact nrows(m) => 3
  @fact ncols(m) => 3
  @fact nrows(v) => 3
  @fact ncols(v) => 1

  m = reshape(collect(1:4),2,2)
  @fact addOnes(collect(1:3)) => Int[1,2,3,1]
  @fact addOnes(collect(1:3.)) => Float64[1,2,3,1]
  @fact addOnes(m) => Int[1 3 1; 2 4 1]

  @fact getPctOfInt(0.5, 10) => 5
  @fact getPctOfInt(1.5, 10) => 10
  @fact splitRange(10, 0.5) => (1:5, 6:10)
  @fact splitMatrixRows(m, 0.5)[1] => rows(m, 1:1)

  @fact stringfloat(0.1111) => "0.111"
  @fact stringfloat(0.1111, 1) => "0.1"
  @fact stringfloats([0.1111, 0.9999], 2) => "[0.11, 1.00]"
end


facts("misc") do
  @fact donothing(5,5) => nothing
  @fact nop(5) => 5
  @fact returntrue(5) => true
end


facts("price") do
  @fact Price(50.55) => CTechCommon.makePrice(5055, 2)
  @fact Price(50.55, 4) => Price(50.55, 2)

  fp = 55.55555
  p = Price(fp)
  @fact p.priceLong => 555556
  @fact p.precision => 4
  @fact p.multiplier => 10_000
  @fact float(p) => roughly(fp)
  @fact CTechCommon.getLong(p, 2) => 5556
  @fact float(p + Price(1.01,2)) => roughly(56.5656)

  p = Price(fp, 2)
  rounded = round(fp, 2)
  @fact p + 0.001 => p
  @fact float(p + 0.005) => roughly(rounded + 0.01)
  @fact float(p * 2) => roughly(rounded * 2)
end


facts("time") do
  # function jacob_calcSecondsEpochToMidnight(secondsSinceEpoch::Integer)
  #   utc = DateTime(Date(Dates.unix2datetime(secondsSinceEpoch)))
  #   adjustment = Dates.Second(div(Dates.value(now() - now(Dates.UTC)),1000))
  #   return Dates.value(utc+adjustment)
  # end

  
end


facts("fixedsym") do
end


facts("bufferedio") do
end


facts("trie") do
end


facts("Logger") do
  @fact log_severity() => InfoSeverity
  @fact log_io() => STDOUT
  log_severity!(DebugSeverity)
  @fact log_severity() => DebugSeverity
  log_severity!(ErrorSeverity)
  @fact log_severity() => ErrorSeverity
  log_severity!(InfoSeverity)
end


facts("markets") do
  @fact typeof(getFee(EDGX, false)) => Float64
  @fact EDGA => less_than(EDGX)
  @fact EXCH_SORTED_BY_TAKE_FEE => [EDGA,EDGX]

  id = generateOID()
  @fact generateOID() => id + 1
  @fact generateOID() => id + 2

  s = "MSFT"
  @fact string(Ticker(s)) => s
  @fact Ticker(s) => s
  @fact Ticker(s) => less_than("NSFT")
end

type TmpVal; val::Int; end
updatetmp(tmpval::TmpVal, newval::Integer) = (tmpval.val = newval; nothing)


# facts("broadcaster") do
#   initBroadcaster(2)
#   tmpval = TmpVal(0)
#   @fact tmpval.val => 0
#   listenfor(updatetmp, tmpval, UID(1))

#   broadcastto(updatetmp, (UID(2),NOEXCHANGE), 5)
#   @fact tmpval.val => 0
#   broadcastto(updatetmp, (UID(1),NOEXCHANGE), 5)
#   @fact tmpval.val => 5
#   broadcastto(updatetmp, (UID(0),NOEXCHANGE), 10)
#   @fact tmpval.val => 10


#   initBroadcaster(2)
#   tmpval = TmpVal(0)
#   @fact tmpval.val => 0
#   listenfor(updatetmp, tmpval, EDGX)

#   broadcastto(updatetmp, (UID(2),EDGA), 5)
#   @fact tmpval.val => 0
#   broadcastto(updatetmp, (UID(1),EDGX), 5)
#   @fact tmpval.val => 5
#   broadcastto(updatetmp, (UID(0),NOEXCHANGE), 10)
#   @fact tmpval.val => 10

# end

type Counter; n::Int; end

facts("pubsub") do
  # TODO test: 
  #   various filters
  #   ordering of connections
  #   function types, argument lists
  #   unregistering

  # simple test function to add the sum of the args to the counter
  handlemsg(c::Counter, args...) = (c.n += sum(args))
  
  reset_hub()
  pub1 = Publisher(handlemsg, Filters([:key1, 5, 6], [:key2, "hi", "yo"]))

  c1 = Counter(0)
  sub1 = subscribe(handlemsg, c1)

  # sub1 should add 1 to c1
  publish(pub1, 1)
  @fact c1.n => 1

  # now both sub1 and sub2 should be subscribed to pub1, so this should add 9 (2+3+4) twice
  sub2 = subscribe(handlemsg, c1, Filters([:key1, 6, 7, 8]))
  publish(pub1, 2,3,4)
  @fact c1.n => 19

  # unregistering sub1, so the next pub should add 10 once
  unregister(sub1)
  publish(pub1, 5,5)
  @fact c1.n => 29

  # sub3 should not be subscribed to pub1
  sub3 = subscribe(handlemsg, c1, Filters([:key2, "word"]))
  publish(pub1, 10)
  @fact c1.n => 39

end


FactCheck.exitstatus()