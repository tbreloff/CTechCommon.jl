

typealias AVec{T} AbstractVector{T}
typealias AVecF AVec{Float64}
typealias AVecI AVec{Int}
typealias VecF Vector{Float64}
typealias VecI Vector{Int}

typealias AMat{T} AbstractMatrix{T}
typealias AMatF AMat{Float64}
typealias AMatI AMat{Int}
typealias MatF Matrix{Float64}
typealias MatI Matrix{Int}

typealias ABytes AVec{UInt8}
typealias Bytes Vector{UInt8}

typealias IntIterable AVecI
typealias FloatIterable AVecF

####################################################

function foreach(A::AbstractArray, f::Function, fs::Function...)
  for x in A
    f(x)
  end
  for g in fs
    foreach(A, g)
  end
  A
end

function getith(iterator, idx::Int)
  for (i,x) in enumerate(iterator)
    if i == idx
      return Nullable(x)
    end
  end
  Nullable{Any}()
end

unzip(x) = [p[1] for p in x], [p[2] for p in x]
sizes(x) = map(size, x)
mapf(functions, obj) = [f(obj) for f in functions]

####################################################

row(M::AMat, i::Integer) = rowvec_view(M, i)
col(M::AMat, i::Integer) = view(M, :, i)
column(M::AMat, i::Integer) = view(M, :, i)

rows(M::AMat, rng::AVecI) = view(M, rng, :)
cols(M::AMat, rng::AVecI) = view(M, :, rng)
columns(M::AMat, rng::AVecI) = view(M, :, rng)

row!{T}(M::AMat{T}, i::Integer, v::AVec{T}) = (M[i,:] = v; nothing)
col!{T}(M::AMat{T}, i::Integer, v::AVec{T}) = (M[:,i] = v; nothing)
column!{T}(M::AMat{T}, i::Integer, v::AVec{T}) = (M[:,i] = v; nothing)


nrows(a::AbstractArray) = size(a,1)
ncols(a::AbstractArray) = size(a,2)

addOnes{T<:Number}(v::AVec{T}) = vcat(v, one(T)) #hcat(v, ones(length(v)))
addOnes{T<:Number}(m::AMat{T}) = hcat(m, ones(T, nrows(m)))

mat(m::AMat) = m
mat(v::AVec) = reshape_view(v, (length(v),))

# --------------------------------------------------------------------------------------

getPctOfInt(pct::Real, T::Integer) = round(Int, max(0., min(1., pct)) * T)

function splitRange(T::Integer, pct::Real)
  lastin = getPctOfInt(pct,T)
  1:lastin, lastin+1:T
end

function splitMatrixRows(m::AMat, pct::Real)
  rng1, rng2 = splitRange(nrows(m), pct)
  rows(m,rng1), rows(m,rng2)
end

stringfloat(v::FloatingPoint, prec::Integer = 3) = format(v, precision = prec)
stringfloats(v::AVecF, prec::Integer = 3) = string("[", join(map(x->stringfloat(x,prec), v), ", "), "]")
