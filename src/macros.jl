


using Base.Meta: isexpr

# ------------------------------------------------------------------


function getStructTypeAndFields(expr)
  if !isexpr(expr, :type)
    error("trying to create constructor for non-type expression")
  end

  #get type name
  args = expr.args
  if isa(args[2],Symbol) structType = args[2]
  elseif isexpr(args[2],:<:) structType = args[2].args[1]
  else error("Unable to extract type name!")
  end

  # loop through all the fields and build an array of types
  fields = []
  for fieldExpr in args[3].args
    if isexpr(fieldExpr, :(::))
      push!(fields, (fieldExpr.args[1], fieldExpr.args[2]))
    end
  end

  return structType, fields
end

function makebody(structType, args)
  body = :($structType())
  append!(body.args, args)
  body
end

# create a new bitstype value by converting a UInt8 pointer to a "ftype" pointer, then load from the pointer
function loadFunction(ftype, s)
  :(unsafe_load(convert(Ptr{$ftype}, pointer(buf,pos+$s))))
end


# ------------------------------------------------------------------

# this macro takes a type definition expression and creates a custom constructor
# to read in from an IO source that is packed binary data
macro packedStruct(expr)

  structType, fields = getStructTypeAndFields(expr)
  fieldTypes = [f[2] for f in fields]

  # create constructors
  defaultConstructorBody = makebody(structType, [:(zero($ft)) for ft in fieldTypes])
  readIOConstructorBody = makebody(structType, [:(read(io, $ft)) for ft in fieldTypes])

  # create the reinterpret function to construct from a position in a byte array
  fsizes = [@eval sizeof($ft) for ft in fieldTypes]
  spos = vcat(1, cumsum(fsizes)[1:end-1] + 1)
  reinterpretBody = makebody(structType, [loadFunction(ft,spos[i]) for (i,ft) in enumerate(fieldTypes)])

  # now return the full expression
  # note: the whole thing is escaped so that this block is executed in calling scope
  # note: "esc(expression)" executes in calling scope, whereas "expression" executes in macro scope
  esc(quote
    $expr
    $structType() = $defaultConstructorBody
    $structType(io::IO) = $readIOConstructorBody
    Base.zero(::Type{$structType}) = $structType()
    Base.read(io::IO, ::Type{$structType}) = $structType(io)
    Base.reinterpret(::Type{$structType}, buf::ABytes, pos::Integer) = $reinterpretBody
    CTechCommon.getPackedStructSize(::Type{$structType}) = $(sum(fsizes))
  end)
end


# ------------------------------------------------------------------

# create print/show methods, assuming string(typ) is defined
macro createIOMethods(typ::Symbol)
  esc(quote
    Base.print(io::IO, o::$typ) = print(io, string(o))
    Base.show(io::IO, o::$typ) = print(io, string(o))
  end)
end

# ------------------------------------------------------------------

macro pretty(expr::Expr)

  structType, fields = getStructTypeAndFields(expr)

  # create a string() expression and add "$sep$fieldname: $fieldexpr" for each field
  strExpr = :(string())
  for (i,f) in enumerate(fields)
    fn = f[1]
    sep = i>1 ? ", " : ""
    ss = "$sep$fn="
    push!(strExpr.args, :($ss))
    push!(strExpr.args, :(xxx.$fn))
  end

  # return the original type expression, along with the new methods to be added
  quote
    $(esc(expr))
    Base.string(xxx::$(esc(structType))) = string($(string(structType)), "{", $strExpr, "}")
    Base.print(io::IO, xxx::$(esc(structType))) = print(io, string(xxx))
    Base.show(io::IO, xxx::$(esc(structType))) = print(io, string(xxx))
  end
end

