
# create print/show methods, assuming string(typ) is defined
macro createIOMethods(typ::Symbol)
  sym = symbol(string(typ,"_obj"))
  expressions = Expr[]
  push!(expressions, :(Base.print(io::IO, $sym::$typ) = print(io, string($sym))))
  push!(expressions, :(Base.show(io::IO, $sym::$typ) = print(io, string($typ,"{",$sym,"}"))))
  # TODO: add write?
  [eval(e) for e in expressions]
end


# # add a string function which nicely shows the fields of a composite
# macro pretty(expr::Expr)

#   eval(expr)

#   structType, fields = getStructTypeAndFields(expr)
#   strExpr = :(string(string($structType),"{"))
#   for (i,f) in enumerate(fields)
#     fn = f[1]
#     sep = i>1 ? ", " : ""
#     ss = "$sep$fn="
#     push!(strExpr.args, :($ss))
#     push!(strExpr.args, :(xxx.$fn))
#   end
#   push!(strExpr.args, :("}"))

#   @eval Base.string(xxx::$structType) = $strExpr
#   @eval Base.print(io::IO, xxx::$structType) = print(io::IO, string(xxx))
#   @eval Base.show(io::IO, xxx::$structType) = print(io::IO, string(xxx))
# end


using Base.Meta: isexpr

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


macro pretty(expr::Expr)
  structType, fields = getStructTypeAndFields(expr)
  # show(structType); println()


  strExpr = :(string())
  for (i,f) in enumerate(fields)
    fn = f[1]
    sep = i>1 ? ", " : ""
    ss = "$sep$fn="
    push!(strExpr.args, :($ss))
    push!(strExpr.args, :(xxx.$fn))
  end
  # push!(strExpr.args, :("}"))
  # show(strExpr)
  # println()

  blk = quote
    $expr
    Base.string(xxx::$(esc(structType))) = string($(string(structType)), "{", $strExpr, "}")
    Base.print(io::IO, xxx::$(esc(structType))) = print(io, string(xxx))
    Base.show(io::IO, xxx::$(esc(structType))) = print(io, string(xxx))
  end

  # show(blk)
  # println()

  push!(blk.args, :nothing)
  blk.head = :toplevel
  blk
end