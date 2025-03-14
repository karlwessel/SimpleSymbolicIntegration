# SimpleSymbolicIntegration

Provides symbolic integration of simple functions like $\sin(x)$ or $\cos(x)$ for Symbolics, SymbolicUtils and any other Symbolic library implementing TermInterface.

Does not really provide integration for functions itself, but instead users can easily define the antiderivatives of the functions they need themself and this library will take care of the rest.

[![CI](https://github.com/karlwessel/SimpleSymbolicIntegration/actions/workflows/CI.yml/badge.svg)](https://github.com/karlwessel/SimpleSymbolicIntegration/actions/workflows/CI.yml)

# Usage
## Installation
```julia
using Pkg
Pkg.add(url="https://github.com/karlwessel/SimpleSymbolicIntegration.git")
```

## First steps
```julia
using SimpleSymbolicIntegration
using Symbolics

@variables x
integrate(sin(2x), x, 0, pi)
```

## Get unknown integrals
Sometimes, when equations are really long, it is useful to get a list of the unknown
integrals in the equation.
```julia
unknownintegrals(integrate(exp(2x + 1), x, 0, 1))
```

Then one can solve them by some substitution or telling the
integration procedure the antiderivative of the unknown integral.

## Define own antiderivatives
```julia
integrate(exp(2x + 1), x, 0, 1; userdb=Dict(exp => exp))
integrate(8*sinpi(2x + 2), x, 0, 1; userdb=Dict(sinpi => x -> -cospi(x) / pi))
```

## Expand all integrals in an equation
```julia
eq = Integral(x in (0, pi))(sin(x))
expandintegrals(eq)
```

# Related packages
[SymbolicNumericIntegration](https://github.com/SciML/SymbolicNumericIntegration.jl): 
Can handle more complicated integrands but the results aren't always reliable and 
computations can take some time.
