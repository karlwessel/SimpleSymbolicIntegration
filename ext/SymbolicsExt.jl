module SymbolicsExt

using SimpleSymbolicIntegration
using Symbolics

SimpleSymbolicIntegration.makeintegral(y::Num, iv, lower, upper, metadata=metadata(y)) = Integral(iv in (lower, upper))(y)

SimpleSymbolicIntegration.integrate(p::Num, iv, from, to) = Symbolics.wrap(integrate(Symbolics.unwrap(p), iv, from, to))

end # module
