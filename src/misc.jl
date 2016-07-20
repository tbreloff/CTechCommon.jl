
donothing(x...) = return
# nop(x) = x
returntrue(x) = true


# type ObjectWrapper
#   obj
# end
# wrap(obj...) = ObjectWrapper(obj)
# unwrap(wrapper::ObjectWrapper) = (obj = wrapper.obj; n = length(obj); (n == 1 ? obj[1] : (n == 0 ? nothing : obj)))
