
function leastsquares(lhs, rhs; bias = false)
  if bias
    rhs = addOnesColumn(rhs)
  end
  rhs \ lhs
end


# regressPLS{T<:Number}(RHS::Vector{T}, LHS, bias = false) = regressPLS(float(reshape(RHS, length(RHS), 1)), LHS, bias)
# regressPLS(RHS, LHS, bias = false) = PartialLeastSquares.regressByPLS(LHS, (bias ? addOnesColumn : nop)(RHS), inSamplePct = 0.9)'

# regress(RHS, LHS, bias = false) = MultivariateStats.llsq(RHS, LHS; bias = bias)'
# regress(RHS, LHS, bias = false) = GLM.lm((bias ? addOnesColumn : nop)(RHS), LHS)

# regressLogit(RHS, LHS) = GLM.glm(RHS, LHS, GLM.Binomial())

logit(x) = log(x ./ (1. - x))
invlogit(x) = 1 ./ (1 + exp(-x))

# solving: logit(LHS) = RHS * beta
function regressLogit(RHS::AMatF, LHS::AVecF)
  @assert nrows(RHS) == length(LHS)
  println("Regressing logit: $(size(RHS)) $(size(LHS))")
  try
    glmresult = GLM.glm(RHS, LHS, GLM.Binomial())
    return GLM.coef(glmresult)
  catch e
    warn("Regression failed with error: $e")
    return zeros(ncols(RHS))
  end
end


function reduceEigMatrix(eigvals::AVecF, eigvecs::AMatF, T::Integer, confidence::FloatingPoint = 0.01)
  # do test to compute r = numCointegratingVecs
  tmp = -T * log(1 - eigvals)
  tracestat = sum(tmp) - cumsum(tmp)
  maxeigstat = [tmp[2:end] ; 0]

  # compute the number of cointegrating vectors by comparing the trace statistic to a
  # chi-squared distribution with r degrees of freedom for the given confidence
  r = 0
  for i = 1:length(eigvals)
    chisqcdf = Distributions.cdf(Distributions.Chisq(i), tracestat[i])
    if chisqcdf > 1 - confidence
      r = i
    end
  end

  # return transpose of first r eigvecs which is (r x k) matrix
  eigvecs[:, 1:r]'
end

