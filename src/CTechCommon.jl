module CTechCommon


using Reexport
@reexport using QuickStructs
@reexport using ArrayViews

import Base.Dates
import Calendar
import Formatting: format

# ----------------------------------------------------------

export
  @createIOMethods,
  @pretty

include("macros.jl")

# ---------------------------------------

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
  addOnes,
  mat,
  getPctOfInt,
  splitRange,
  splitMatrixRows,
  stringfloat,
  stringfloats

include("arrays.jl")

# ---------------------------------------

export
  wrap,
  unwrap,
  donothing,
  nop,
  returntrue

include("misc.jl")

# ---------------------------------------

export
  Price

include("price.jl")

# ---------------------------------------

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

# ---------------------------------------

export
  FixedLengthSymbol,
  Symbol6,
  Symbol8

include("fixedsym.jl")

# ---------------------------------------

export 
  BufferedIOStream

include("bufio.jl")

# ---------------------------------------

export
  TrieChar,
  TrieNode,
  buildTrie

include("trie.jl")

# ---------------------------------------

export
  LOG,
  @LOG,
  ERROR,
  @ERROR,
  DEBUG,
  @DEBUG,
  log_severity,
  log_severity!,
  log_io,
  log_io!,
  Info,
  Error,
  Debug

include("logger.jl")

# ---------------------------------------

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
  EXCH_SORTED_BY_TAKE_FEE,
  OID,
  UID,
  iszero,
  generateOID,
  Ticker,
  marketOpenUS,
  marketCloseUS

include("markets.jl")

# ---------------------------------------

export
  initBroadcaster,
  listenfor,
  broadcastto

include("broadcaster.jl")

# ---------------------------------------

end # module
