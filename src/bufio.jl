
# BufferedIOStream wraps an IO source intended for binary data
# When there's not enough size remaining in the buffer, we copy the unread bytes
# to the front, and fill the buffer from the underlying IO
# On read, we expect a bitstype (or immutable of bitstypes) so that we can reinterpret the bytes

# Note: there's no copying on reinterpret, so be careful about keeping these objects around! 

type BufferedIOStream
	io::IOStream
	ioSz::Int64
	ioPos::Int64
	# cfile::CFILE
	cfile::Libc.FILE
	buf::Bytes   
	pos::Int64   # current position in the array
	filled::Int64  # the number of bytes filled currently
	bufSz::Int64  # size of buf

	BufferedIOStream(io::IOStream) = BufferedIOStream(io, 512)
	BufferedIOStream(io::IOStream, sz::Integer) = new(io, stat(io).size, 0, Libc.FILE(io), zeros(UInt8,sz), 0, 0, sz)
end

Base.string(bufio::BufferedIOStream) = "BufferedIOStream{io=$(bufio.io) ioSz=$(bufio.ioSz) pos=$(bufio.pos) filled=$(bufio.filled) bufSz=$(bufio.bufSz)}"
Base.print(io::IO, bufio::BufferedIOStream) = print(io, string(bufio))
Base.show(io::IO, bufio::BufferedIOStream) = print(io, string(bufio))

# how many bytes have we buffered but not yet read?
nb_buffered(bufio::BufferedIOStream) = bufio.filled - bufio.pos

# how many more bytes can we add to the buffer?
nb_empty(bufio::BufferedIOStream) = bufio.bufSz - bufio.filled

# how many bytes left in the stream that have not yet been buffered?
nb_remaining(bufio::BufferedIOStream) = bufio.ioSz - bufio.ioPos

# how many total bytes remaining to be processed?
nb_available(bufio::BufferedIOStream) = nb_buffered(bufio) + nb_remaining(bufio)

# eof?
Base.eof(bufio::BufferedIOStream) = (nb_available(bufio) <= 0)

# we want to read sz bytes, so fill the buffer if needed
function ensureDataIsInBuffer!(bufio::BufferedIOStream, sz::Integer)
	
	# first make sure the buf is big enough
	if bufio.bufSz < sz
		error("bufSz too small! wanted sz=$sz, but bufSz=$(bufio.bufSz)")
	end

	nb_buf = nb_buffered(bufio)
	if nb_buf < sz
		# need more data in buffer

		# copy buffered data to front
		buf = bufio.buf
		pos = bufio.pos
		if nb_buf > 0	
			for i = 1:nb_buf
				buf[i] = buf[pos+i]
			end
		end

		# set start/end
		bufio.pos = 0
		bufio.filled = nb_buf

		# read in remaining
		fillBuffer!(bufio)
	end
end

# this function is specific to IOStreams... it calls the c function fread to read the
# block of data all at once into the buffer
function fillBuffer!(bufio::BufferedIOStream)
	szToRead = nb_empty(bufio)
	# szRead = ccall(:fread, Cint, (Ptr{Void}, Cint, Cint, CFILE), pointer(bufio.buf, bufio.filled+1), 1, szToRead, bufio.cfile)
	szRead = ccall(:fread, Csize_t, (Ptr{Void}, Csize_t, Csize_t, Ptr{Void}), pointer(bufio.buf, bufio.filled+1), 1, szToRead, bufio.cfile)
	if szRead > 0
		bufio.filled += szRead
		bufio.ioPos += szRead
	end
end

function Base.read!{T}(bufio::BufferedIOStream, ::Type{T})
	structSize = getPackedStructSize(T)
	ensureDataIsInBuffer!(bufio, structSize)
	castFromBuffer!(bufio, T, structSize)
end

# note: this function takes a slice from the buffer and fills a new object
function castFromBuffer!{T}(bufio::BufferedIOStream, ::Type{T}, structSize::Integer)
	obj = reinterpret(T, bufio.buf, bufio.pos)
	bufio.pos += structSize
	obj
end



# # read directly into an existing object
# function read!{T}(bufio::BufferedIOStream, obj::T)
# 	structSize = getPackedStructSize(T)
# 	ensureDataIsInBuffer!(bufio, structSize)
# 	castFromBuffer!(bufio, obj, structSize)
# end

# # note: this function takes a slice from the buffer and fills an existing object
# function castFromBuffer!{T}(bufio::BufferedIOStream, obj::T, structSize::Integer)
# 	# obj = reinterpret(T, bufio.buf, bufio.pos)
# 	fillFromBuf(obj, bufio.buf, bufio.pos)
# 	bufio.pos += structSize
# 	return
# end
