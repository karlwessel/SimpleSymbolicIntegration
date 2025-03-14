module SymbolicsExt

import SimpleSymbolicIntegration
using Symbolics
using Symbolics: wrap, unwrap
using TermInterface

SimpleSymbolicIntegration.makeintegral(y, iv::Num, lower, upper, metadata=metadata(y)) = unwrap(Integral(iv in (lower, upper))(y))

SimpleSymbolicIntegration.integrate(p::Num, iv, lower, upper; userdb=Dict()) = wrap(SimpleSymbolicIntegration.integrate(unwrap(p), iv, lower, upper; userdb))

isintegral(ex) = operation(ex) isa Integral

SimpleSymbolicIntegration.unknownintegrals(ex::Num) = wrap.(_unknownintegrals(unwrap(ex)))

function _unknownintegrals(ex)
    if iscall(ex)
        unknown = vcat(map(_unknownintegrals, arguments(ex))...)
        if isintegral(ex)
            push!(unknown, ex)
        end
        return unique(unknown)
    end
    return []
end

end # module
