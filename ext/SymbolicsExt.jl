module SymbolicsExt

import SimpleSymbolicIntegration: makeintegral, integrate, unknownintegrals, expandintegrals
using Symbolics
using Symbolics: wrap, unwrap
using TermInterface
using DomainSets
using SymbolicUtils: BasicSymbolic

makeintegral(y, iv::Num, lower, upper, metadata=metadata(y)) = Integral(iv in (lower, upper))(y)

# For differentials Symbolics splits differentials of complex symbols into differential of each part
# for integrals it does not do that, but we do this here
makeintegral(y::Complex{Num}, iv::Num, lower, upper, metadata=metadata(y)) = 
	wrap(Symbolics.ComplexTerm{Real}(
		makeintegral(real(y), iv, lower, upper, metadata), 
		makeintegral(imag(y), iv, lower, upper, metadata)))
makeintegral(y::Symbolics.ComplexTerm{Real}, iv::Num, lower, upper, metadata=metadata(y)) = makeintegral(wrap(y), iv, lower, upper)

integrate(p::Num, iv, lower, upper; userdb=Dict()) = wrap(integrate(unwrap(p), iv, lower, upper; userdb))

integrate(p::Complex{Num}, iv, lower, upper; userdb=Dict()) = wrap(Symbolics.ComplexTerm{Real}(integrate(real(p), iv, lower, upper; userdb), 
integrate(imag(p), iv, lower, upper; userdb)))

isintegral(ex) = operation(ex) isa Integral

unknownintegrals(ex::Num) = wrap.(_unknownintegrals(unwrap(ex)))
unknownintegrals(p::Complex{Num}) = vcat(unknownintegrals(real(p)), 
unknownintegrals(imag(p)))


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

expandintegrals(ex::Num; userdb=Dict()) = wrap(_expandintegrals(unwrap(ex); userdb))

expandintegrals(p::Complex{Num}; userdb=Dict()) = wrap(Symbolics.ComplexTerm{Real}(expandintegrals(real(p); userdb), 
expandintegrals(imag(p); userdb)))

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
            ex = integrate(integrand, iv, a, b; userdb)
        else
            ex = op(args...)
        end
    end
    return ex
end

# Complex may represent one or zero as true or false respectively, therefor
# we need to be able to integrate those
integrate(x::Bool, iv, lower, upper; userdb=Dict()) = integrate(x ? one(iv) : zero(iv), iv, lower, upper; userdb)


# Symbolics Integral call returns a BasicSymbolic{Complex{Num}} for complex integrands, this should catch those cases
function splitcomplexintegrand(p)
	op = operation(p)
	if op isa Integral
		# convert integrand to Complex{Num}
		arg = only(arguments(p))
		
		return wrap(Symbolics.ComplexTerm{Real}(op(unwrap(real(arg))), op(unwrap(imag(arg)))))
	else
		@warn "Converting an operation on Complex{Num} that is not an integration!"
		# cross fingers, hope for the best, this is going to get ugly....
		# convert argument to ComplexTerm
		return op(unwrap.(arguments(p))...)
	end
end
integrate(p::BasicSymbolic{Complex{Num}}, iv, lower, upper; userdb=Dict()) = wrap(integrate(splitcomplexintegrand(p), iv, lower, upper; userdb))
unknownintegrals(p::BasicSymbolic{Complex{Num}}) = wrap.(unknownintegrals(splitcomplexintegrand(p)))
expandintegrals(p::BasicSymbolic{Complex{Num}}; userdb=Dict()) = wrap(expandintegrals(splitcomplexintegrand(p); userdb))

end # module
