# SimpleSymbolicIntegration

Provides symbolic integration of simple functions like $sin$ or $cos$ for Symbolics, SymbolicUtils and any other Symbolic library implementing TermInterface.

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

## Define own antiderivatives
```julia
integrate(exp(2x + 1), x, 0, 1; userdb=Dict(exp => exp))
integrate(8*sinpi(2x + 2), x, 0, 1; userdb=Dict(sinpi => x -> -cospi(x) / pi))
```

