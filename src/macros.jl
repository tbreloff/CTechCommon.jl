
# create print/show methods, assuming string(typ) is defined
macro createIOMethods(typ::Symbol)
  sym = symbol(string(typ,"_obj"))
  expressions = Expr[]
  push!(expressions, :(Base.print(io::IO, $sym::$typ) = print(io, string($sym))))
  push!(expressions, :(Base.show(io::IO, $sym::$typ) = print(io, string($typ,"{",$sym,"}"))))
  # TODO: add write?
  [eval(e) for e in expressions]
end


# add a string function which nicely shows the fields of a composite
macro pretty(expr::Expr)

  eval(expr)

  structType, fields = getStructTypeAndFields(expr)
  strExpr = :(string(string($structType),"{"))
  for (i,f) in enumerate(fields)
    fn = f[1]
    sep = i>1 ? ", " : ""
    ss = "$sep$fn="
    push!(strExpr.args, :($ss))
    push!(strExpr.args, :(xxx.$fn))
  end
  push!(strExpr.args, :("}"))

  @eval Base.string(xxx::$structType) = $strExpr
  @eval Base.print(io::IO, xxx::$structType) = print(io::IO, string(xxx))
  @eval Base.show(io::IO, xxx::$structType) = print(io::IO, string(xxx))
end
