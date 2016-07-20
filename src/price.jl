
immutable Price
  priceLong::Int
  precision::Int
  multiplier::Int
end

# create a price directly with the priceLong and precision
function makePrice(priceLong::Integer, precision::Int)
  if precision < 0 || precision > 10
    error("Price precision invalid: $precision")
  end
  Price(Int(priceLong), precision, 10^precision)
end

# this creates a price from a number, with given precision
Price(priceval::Number, precision::Int = 4) = makePrice(round(Int, priceval * (10^precision)), precision)

# this converts a price to a new precision
function Price(price::Price, precision::Int)
  priceLong = getLong(price, precision)
  makePrice(priceLong, precision)
end

Base.zero(::Type{Price}) = Price(0)
iszero(price::Price) = price.priceLong == 0

Base.String(price::Price) = format(price.priceLong / price.multiplier, precision = price.precision, commas = true)
# @createIOMethods Price
Base.convert(::Type{Price}, n::Number) = Price(n)
Base.convert{T<:AbstractFloat}(::Type{T}, p::Price) = p.priceLong / p.multiplier


function getLong(p::Price, precision::Int)
  if precision == p.precision
    return p.priceLong
  elseif precision > p.precision
    p.priceLong * 10^(precision - p.precision)
  else
    # warn("Reducing precision in Price: ", p)
    round(Int, p.priceLong / 10^(p.precision - precision))
  end
end


function expand(p1::Price,p2::Price)
  precision = max(p1.precision, p2.precision)
  (getLong(p1, precision), getLong(p2, precision))
end

Base.typemin(::Type{Price}) = zero(Price)
Base.typemax(::Type{Price}) = Price(typemax(Int))
for op in (:<, :>, :(==), :<=, :>=, :(Base.isless))
  @eval $op(p1::Price, p2::Price) = (p1.precision == p2.precision ? $op(p1.priceLong, p2.priceLong) : $op(expand(p1,p2)...))
end

Base.mean(p1::Price, p2::Price) = convert(Price, (Float64(p1) + Float64(p2)) / 2)
Base.log(p::Price) = log(Float64(p))

# typealias PriceOrNumber Union(Price, Number)
for op in (:+, :-, :*, :/, :.*, :./, :dot)
  # @eval $op(p1::PriceOrNumber, p2::PriceOrNumber) = $op(Float64(p1), Float64(p2))
  @eval $op(p1::Price, p2::Number) = Price($op(Float64(p1), Float64(p2)), p1.precision)
  @eval $op(p1::Number, p2::Price) = Price($op(Float64(p1), Float64(p2)), p2.precision)
  @eval $op(p1::Price, p2::Price) = Price($op(Float64(p1), Float64(p2)), max(p1.precision, p2.precision))
end
