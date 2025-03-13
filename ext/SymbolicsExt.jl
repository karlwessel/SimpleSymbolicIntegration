module SymbolicsExt

using SimpleSymbolicIntegration
using Symbolics
using TermInterface

SimpleSymbolicIntegration.makeintegral(::Type{Num}, y, iv, lower, upper, metadata=metadata(y)) = Integral(iv in (lower, upper))(y)

SimpleSymbolicIntegration.integrate(p::Num, iv, lower, upper; userdb=Dict()) = Symbolics.wrap(integrate(Symbolics.unwrap(p), iv, lower, upper; symtype=Num, userdb))

end # module
