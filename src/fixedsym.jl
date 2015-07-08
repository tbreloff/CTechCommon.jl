

#############################################
# FixedLengthSymbol
#############################################

# FixedLengthSymbol types... Symbol6 and Symbol8 are fixed width types used for reading in symbols from a binary feed handler

abstract FixedLengthSymbol

immutable Symbol6 <: FixedLengthSymbol
  s1::UInt8
  s2::UInt8
  s3::UInt8
  s4::UInt8
  s5::UInt8
  s6::UInt8
end

Base.sizeof(::Type{Symbol6}) = 6
Base.zero(::Type{Symbol6}) = Symbol6(0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
Base.read(io::IO, ::Type{Symbol6}) = Symbol6(read(io,UInt8), read(io,UInt8), read(io,UInt8), read(io,UInt8), read(io,UInt8), read(io,UInt8))

immutable Symbol8 <: FixedLengthSymbol
  s1::UInt8
  s2::UInt8
  s3::UInt8
  s4::UInt8
  s5::UInt8
  s6::UInt8
  s7::UInt8
  s8::UInt8
end


Base.sizeof(::Type{Symbol8}) = 8
Base.zero(::Type{Symbol8}) = Symbol8(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
Base.read(io::IO, ::Type{Symbol8}) = Symbol8(read(io,UInt8), read(io,UInt8), read(io,UInt8), read(io,UInt8), read(io,UInt8), read(io,UInt8), read(io,UInt8), read(io,UInt8))


isvalidchar(c::UInt8) = (c != 0x00 && c != 0x20)

function lastValidChar{T<:FixedLengthSymbol}(s::T)
  for i = 1:sizeof(T)
    if !isvalidchar(getfield(s, T.names[i]))
      return i-1
    end
  end
  return sizeof(T)
end

function Base.string{T<:FixedLengthSymbol}(s::T)
  lastValid = lastValidChar(s)
  a = Array(UInt8, lastValid)
  for i = 1:lastValid
    a[i] = getfield(s, T.names[i])
  end
  ascii(a)
end

function Base.print{T<:FixedLengthSymbol}(io::IO, s::T)
  for i = 1:sizeof(T)
    local c = getfield(s, T.names[i])
    if isvalidchar(c)
      print(io, convert(Char, c))
    else
      return
    end
  end
end

Base.show{T<:FixedLengthSymbol}(io::IO, s::T) = (print(io, "$T{"); print(io, s); print(io, "}"))

