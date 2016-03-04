
time_to_hours(t::TimeOfDay) = float(t)*1e-12/3.6

# we can add methods dynamically
Base.push!(plt::Plot, i::Integer, p::Price) = push!(plt, i, float(p))
Base.push!(plt::Plot, i::Integer, t::TimeOfDay, p) = push!(plt, i, time_to_hours(t), float(p))

# TODO: generalize this better, so we can just pass a conversion function?

function Plots.convertToAnyVector(ts::AbstractVector{TimeOfDay}; kw...)
    Any[map(time_to_hours, ts)], nothing
end

function Plots.convertToAnyVector(tmat::AbstractMatrix{TimeOfDay}; kw...)
    Any[map(time_to_hours, vec(tmat[:,i])) for i in size(tmat,2)], nothing
end

function Plots.convertToAnyVector(ps::AbstractVector{Price}; kw...)
    Any[map(float, ps)], nothing
end

function Plots.convertToAnyVector(pmat::AbstractMatrix{Price}; kw...)
    Any[map(float, vec(pmat[:,i])) for i in size(pmat,2)], nothing
end

