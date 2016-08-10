__precompile__()

module CTechCommon

using QuickStructs

# import Base.Dates
using TimeZones
import Formatting: format
using RecipesBase

import Base: ==, >, <, >=, <=, +, -, *, /, .*, ./

# ----------------------------------------------------------

export
  @packedStruct
  # @createIOMethods,
  # @pretty

include("macros.jl")

# ---------------------------------------

export 
  # AVec,
  # AVecF,
  # AVecI,
  # VecF,
  # VecI,
  # AMat,
  # AMatF,
  # AMatI,
  # MatF,
  # MatI,
  # ABytes,
  # Bytes,
  # AbstractVector{Int},
  # FloatIterable,
  # foreach,
  getith,
  unzip,
  # sizes,
  mapf,
  # row,
  # col,
  # column,
  # rows,
  # cols,
  # columns,
  # row!,
  # col!,
  # column!,
  # ncols,
  # nrows,
  # addOnes,
  # mat,
  getPctOfInt,
  splitRange,
  splitMatrixRows,
  stringfloat,
  stringfloats

include("arrays.jl")

# ---------------------------------------

export
#   wrap,
#   unwrap,
  donothing,
#   nop,
  returntrue

include("misc.jl")

# ---------------------------------------

export
  Price,
  makePrice

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
  TimeOfDay,
  NegativeTimeOfDayError,
  calcSecondsEpochToMidnight,
  currentTimeOfDay

include("time.jl")

# ---------------------------------------

export 
  BufferedIOStream,
  getPackedStructSize

include("bufio.jl")

export
  MMapIO
include("mmapio.jl")

# ---------------------------------------

export
  FixedLengthSymbol,
  Symbol6,
  Symbol8

include("fixedsym.jl")

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
  DebugSeverity,
  InfoSeverity,
  ErrorSeverity

include("logger.jl")

# ---------------------------------------

export 
  Exchange,
  NOEXCHANGE,
  EDGX,
  EDGA,
  BZX,
  BYX,
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
  reset_hub,
  Filters,
  Publisher,
  publish,
  subscribe,
  unregister,
  Callback

include("pubsub.jl")

# ---------------------------------------

export
  NOW,
  schedule_do,
  process_until,
  initScheduler,
  stopScheduler,
  processAllEvents

include("scheduler.jl")

# ---------------------------------------

include("plots.jl")

# ---------------------------------------

function __init__()
  global const LOG_SEVERITY = SevObj(InfoSeverity, STDOUT)
end

end # module
