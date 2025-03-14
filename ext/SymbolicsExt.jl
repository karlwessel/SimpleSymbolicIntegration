module SymbolicsExt

import SimpleSymbolicIntegration
using Symbolics
using Symbolics: wrap, unwrap
using TermInterface
using DomainSets

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

SimpleSymbolicIntegration.expandintegrals(ex::Num; userdb=Dict()) = wrap(_expandintegrals(unwrap(ex); userdb))

function _expandintegrals(ex; userdb=Dict())
    localexpand(x) = _expandintegrals(x; userdb)
    if iscall(ex)
        op = operation(ex)
        args = map(localexpand, arguments(ex))
        if isintegral(ex)
            op = operation(ex)
            iv = op.domain.variables
            a, b = DomainSets.endpoints(op.domain.domain)
            integrand = only(args)
            ex = SimpleSymbolicIntegration.integrate(integrand, iv, a, b; userdb)
        else
            ex = op(args...)
        end
    end
    return ex
end

end # module
