
immutable MMapIO
	# buf::Vector{UInt8}
	# pos::Int  # NOTE: zero-indexed!
	io::IOBuffer
end

# could pass in a filename or IOStream
MMapIO(arg::Union{AbstractString,IOStream}) = MMapIO(IOBuffer(Mmap.mmap(arg)))

Base.show(io::IO, mmio::MMapIO) = "MMapIO{$(length(mmio.buf)) @ $(mmio.pos)}"


Base.eof(mmio::MMapIO) = eof(mmio.io) #mmio.pos >= length(mmio.buf)
Base.read{T}(mmio::MMapIO, ::Type{T}) = read(mmio.io, T)

# function Base.read!{T}(mmio::MMapIO, ::Type{T})
# 	struct_size = getPackedStructSize(T)
# 	if mmio.pos + struct_size > length(mmio.buf)
# 		@show mmio.pos struct_size length(mmio.buf)
# 		throw(EOFError())
# 	end
# 	obj = reinterpret(T, mmio.buf, mmio.pos)
# 	mmio.pos += struct_size
# 	obj
# end

