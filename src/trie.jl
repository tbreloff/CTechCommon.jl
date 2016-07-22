

#############################################
# Trie string approximate implementation
#############################################

# here we create a tree where each node is a letter, and the child nodes are the next letter in the string
# to find the UID for a string, we traverse the tree one letter at a time until we find the UID (or not!)

immutable TrieChar
  byte::UInt8
end
TrieChar() = TrieChar(0x00)

# Base.string(c::TrieChar) = ascii([c.byte])
Base.print(io::IO, c::TrieChar) = print(io, string(c))
Base.show(io::IO, c::TrieChar) = show(io, string(c))
Base.hash(c::TrieChar) = c.byte
==(c1::TrieChar, c2::TrieChar) = c1.byte == c2.byte


type TrieNode{T}
    children::Dict{TrieChar,TrieNode{T}}
    # parentChain::String
    # istail::Bool
    data::Nullable{T}  # note: this will be undefined except for tail nodes

    # TrieNode{T}(::Type{T}) = new(Dict{TrieChar,TrieNode{T}}(), "", false)
    # TrieNode{T}(::Type{T}, parentChain::String) = new(Dict{TrieChar,TrieNode{T}}(), parentChain, false)
    TrieNode() = new(Dict{TrieChar,TrieNode{T}}(), Nullable{T}())
end
# TrieNode{T}(::Type{T}) = TrieNode{T}(T)

function TrieNode{K}(::Type{K}, strings::Vector{String})
    rootNode = TrieNode{K}()
    for (i,s) in enumerate(strings)
        get!(rootNode, s, K(i))
    end
    rootNode
end

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

function Base.get!{T<:FixedLengthSymbol, K}(rootNode::TrieNode{K}, s::T, default::K)
    node = rootNode
    for b in s.data
        # we're done if null char or space
        if b == 0x00 || b == 0x20
            break
        end

        # set node to be the next node in the tree (add one if needed)
        c = TrieChar(b)
        if haskey(node.children, c)
            node = node.children[c]
        else
            newnode = TrieNode(K)
            node.children[c] = newnode
            node = newnode
        end

        # node = get!(node.children, TrieChar(b), TrieNode(K))

    end

    # add the tail
    if isnull(node.data)
        node.data = Nullable(default)
    end
    get(node.data)

    # maketail!(node, default)

    # node
end

