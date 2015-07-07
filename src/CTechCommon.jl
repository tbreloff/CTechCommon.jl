module CTechCommon


if VERSION < v"0.4-"
    import Dates
else
    import Base.Dates
end

using Reexport
@reexport using QuickStructs
@reexport using ArrayViews

import Calendar

# ----------------------------------------------------------


export 
  AVec,
  AVecF,
  AVecI,
  VecF,
  VecI,
  AMat,
  AMatF,
  AMatI,
  MatF,
  MatI,
  ABytes,
  Bytes,
  foreach,
  getith,
  unzip,
  sizes,
  mapf,
  row,
  col,
  column,
  rows,
  cols,
  columns,
  row!,
  col!,
  column!,
  ncols,
  nrows,
  addOnesColumn,
  mat,
  getPctOfInt,
  splitRange,
  splitMatrixRows,
  stringfloat,
  stringfloats

include("arrays.jl")

export
  wrap,
  unwrap,
  donothing,
  nop,
  returntrue

include("misc.jl")

export 
  Exchange,
  NOEXCHANGE,
  EDGX,
  EDGA,
  exchange,
  getLatency,
  getTakeFee,
  getProvideFee,
  getFee,
  getPriceAdjustmentFromFee,
  OID,
  UID,
  iszero,
  generateOID,
  Ticker,
  marketOpenUS,
  marketCloseUS

include("markets.jl")

export
  Price

include("price.jl")

export
  millisInOneSecond,
  microsInOnSecond,
  nanosInOneSecond,
  nanosInOneMilli,
  nanosInOneMicro,
  secondsInOneMinute,
  secondsInOneHour,
  secondsInOneDay,
  nanosInOneMinute,
  nanosInOneHour,
  nanosInOneDay,
  NOW,
  TimeOfDay,
  NegativeTimeOfDayError

include("time.jl")

export 
  BufferedIOStream

include("bufio.jl")

export
  TrieChar,
  TrieNode,
  buildTrie

include("trie.jl")

export
  leastsquares,
  logit,
  invlogit,
  regressLogit,
  reduceEigMatrix

include("linalg.jl")

# TODO: export
include("logger.jl")

# TODO: export
include("broadcaster.jl")

end # module
