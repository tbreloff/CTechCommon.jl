using CTechCommon
using FactCheck

facts("Logger") do
  @fact log_severity() => Info
  @fact log_io() => STDOUT

end
