

#############################################
# Trie string approximate implementation
#############################################

# here we create a tree where each node is a letter, and the child nodes are the next letter in the string
# to find the UID for a string, we traverse the tree one letter at a time until we find the UID (or not!)

immutable TrieChar
  byte::UInt8
end
TrieChar() = TrieChar(0x00)

Base.string(c::TrieChar) = ascii([c.byte])
Base.print(io::IO, c::TrieChar) = print(io, string(c))
Base.show(io::IO, c::TrieChar) = show(io, string(c))
Base.hash(c::TrieChar) = c.byte
==(c1::TrieChar, c2::TrieChar) = c1.byte == c2.byte


type TrieNode{T}
  children::Dict{TrieChar,TrieNode{T}}
  # parentChain::ASCIIString
  istail::Bool
  data::T  # note: this will be undefined except for tail nodes

  # TrieNode{T}(::Type{T}) = new(Dict{TrieChar,TrieNode{T}}(), "", false)
  # TrieNode{T}(::Type{T}, parentChain::ASCIIString) = new(Dict{TrieChar,TrieNode{T}}(), parentChain, false)
  TrieNode{T}(::Type{T}) = new(Dict{TrieChar,TrieNode{T}}(), false)
end
TrieNode{T}(::Type{T}) = TrieNode{T}(T)
# TrieNode{T}(::Type{T}, parentChain::ASCIIString) = TrieNode{T}(T, parentChain)

function maketail!{T}(node::TrieNode{T}, data::T)
  node.istail = true
  node.data = data
  return
end


function Base.get{T<:FixedLengthSymbol, K}(rootNode::TrieNode{K}, s::T, default::K)
  node::TrieNode{K}
  node = rootNode

  for i in 1:sizeof(T)
    b = getfield(s, i)
    if b == 0x00 || b == 0x20
      break
    end

    c = TrieChar(b)
    if haskey(node.children, c)
      node = node.children[TrieChar(b)]
    else
      return default
    end
    # node = get(node.children, TrieChar(b)) do
    #   return default
    # end
  end

  if node.istail
    return node.data
  else
    return default
  end
end


function buildTrie(strings::Vector{ASCIIString})
  rootNode = TrieNode(UID)

  for (i,s) in enumerate(strings)
    node = rootNode

    for b in s.data

      # we're done if null char or space
      if b == 0x00 || b == 0x20
        break
      end

      # get the next node in the tree
      node = get!(node.children, TrieChar(b), TrieNode(UID))

    end

    # add the tail
    maketail!(node, UID(i))
  end

  rootNode
end