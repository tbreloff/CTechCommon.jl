
const marketOpenUS = TimeOfDay("9:30")
const marketCloseUS = TimeOfDay("16")

#############################################
# Exchange
#############################################


@enum Exchange NOEXCHANGE EDGX EDGA
const NUMEXCHANGE = length(Exchange)
exchange(s::String) = eval(symbol(s))
exchange(e::Exchange) = string(e)

const EXCH_LATENCY_NANOS = [Int(x * 1e3) for x in (199, 200)]
const EXCH_TAKE_FEES = [0.0035, 0.0]
const EXCH_PROVIDE_FEES = [-0.0025, 0.0010]
getLatency(exch::Exchange) = (exch.val > 0 ? EXCH_LATENCY_NANOS[exch.val] : 0) 
getTakeFee(exch::Exchange) = (exch.val > 0 ? EXCH_TAKE_FEES[exch.val] : 0.)
getProvideFee(exch::Exchange) = (exch.val > 0 ? EXCH_PROVIDE_FEES[exch.val] : 0.)
getFee(exch::Exchange, istake::Bool) = (istake ? getTakeFee : getProvideFee)(exch)
getPriceAdjustmentFromFee(exch::Exchange, buy::Bool, istake::Bool) = (buy ? 1 : -1) * getFee(exch, istake)

Base.isless(e1::Exchange, e2::Exchange) = getTakeFee(e1) < getTakeFee(e2)
const EXCH_SORTED_BY_TAKE_FEE = sort([EDGX,EDGA])

####################################################
# IDs
####################################################



typealias OID UInt64
typealias UID UInt64

# OID() = OID(0)
# UID() = UID(0)
iszero(oid::OID) = oid == 0
iszero(uid::UID) = uid == 0

type OID_Generator
  lastoid::OID
end
const OID_GENERATOR = OID_Generator(1e15)
function generateOID()
  OID_GENERATOR.lastoid += 1
  OID_GENERATOR.lastoid
end




#############################################
# Ticker
#############################################

immutable Ticker
  symbol::ASCIIString

  Ticker(symbol::ASCIIString) = new(strip(symbol))
  Ticker(byteArray::Bytes) = Ticker(ascii(byteArray))
  Ticker{T<:FixedLengthSymbol}(sym::T) = Ticker(sym.data)
end

Base.string(ticker::Ticker) = ticker.symbol
Base.hash(ticker::Ticker) = hash(ticker.symbol)
@createIOMethods Ticker
Base.convert(::Type{Ticker}, s::String) = Ticker(ascii(s))

for op in (:<, :>, :(==), :<=, :>=, :(Base.isless))
  @eval $op(t1::Ticker, t2::Ticker) = $op(t1.symbol, t2.symbol)
  @eval $op(t1::Ticker, t2::String) = $op(t1.symbol, t2)
  @eval $op(t1::String, t2::Ticker) = $op(t1, t2.symbol)
end