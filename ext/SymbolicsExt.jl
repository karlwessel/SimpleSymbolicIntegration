module SymbolicsExt

using SimpleSymbolicIntegration
using Symbolics
using TermInterface

makeintegral(y, iv, lower, upper, metadata=metadata(y)) = Symbolics.unwrap(Integral(iv in (lower, upper))(y))

SimpleSymbolicIntegration.integrate(p::Num, iv, lower, upper; userdb=Dict()) = Symbolics.wrap(integrate(Symbolics.unwrap(p), iv, lower, upper; makeintegral=makeintegral, userdb))

end # module
