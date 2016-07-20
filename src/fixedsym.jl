
# FixedLengthSymbol types... Symbol6 and Symbol8 are fixed width types used for reading in symbols from a binary feed handler

abstract FixedLengthSymbol
# @createIOMethods FixedLengthSymbol
isvalidchar(c::UInt8) = (c != 0x00 && c != 0x20)


@packedStruct immutable Symbol6 <: FixedLengthSymbol
  s1::UInt8
  s2::UInt8
  s3::UInt8
  s4::UInt8
  s5::UInt8
  s6::UInt8
end
Base.sizeof(::Type{Symbol6}) = 6
function Base.String(s::Symbol6)
  buf = IOBuffer(6)
  isvalidchar(s.s1) && write(buf, s.s1)
  isvalidchar(s.s2) && write(buf, s.s2)
  isvalidchar(s.s3) && write(buf, s.s3)
  isvalidchar(s.s4) && write(buf, s.s4)
  isvalidchar(s.s5) && write(buf, s.s5)
  isvalidchar(s.s6) && write(buf, s.s6)
  String(buf)
end


@packedStruct immutable Symbol8 <: FixedLengthSymbol
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
function Base.String(s::Symbol8)
  buf = IOBuffer(8)
  isvalidchar(s.s1) && write(buf, s.s1)
  isvalidchar(s.s2) && write(buf, s.s2)
  isvalidchar(s.s3) && write(buf, s.s3)
  isvalidchar(s.s4) && write(buf, s.s4)
  isvalidchar(s.s5) && write(buf, s.s5)
  isvalidchar(s.s6) && write(buf, s.s6)
  isvalidchar(s.s7) && write(buf, s.s7)
  isvalidchar(s.s8) && write(buf, s.s8)
  String(buf)
end
