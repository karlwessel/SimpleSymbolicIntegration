using SimpleSymbolicIntegration
using Test
using SymbolicUtils
using Symbolics
import SimpleSymbolicIntegration: occursin, simplederivative, makeintegral
import Symbolics: unwrap

@testset "simplederivative" begin
    x, y = @syms x y
    D(p) = simplederivative(p, x)

    @test isequal(0, D(2))
    @test isequal(0, D(y))
    @test isequal(0, D(sin(y)))
    @test isequal(1, D(x))
    @test isequal(2, D(2x))
    @test isequal(y, D(y*x))
    @test occursin(D(sin(x)), x)
end

@testset "integration" begin
    x, y = @syms x y
    @test !occursin(2, x)
    @test occursin(x, x)
    @test !occursin(y, x)
    @test occursin(sin(x), x)
    @test !occursin(sin(y), x)

    @test 2 == integrate(x, x, 0, 2)
    @test isequal(2y, integrate(y, x, 0, 2))
    @test isequal(2y, integrate(y*sin(x), x, 0, pi))
    @test iszero(integrate(sin(x), x, 0, 2pi))
    @test isequal(2, integrate(sin(x), x, 0, pi))
    @test isequal(2(sin(y) + 2), integrate(sin(y)+2, x, 0, 2))
    @test isequal(2y + 2, integrate(x + y, x, 0, 2))
    @test isequal(0, integrate(sin(2x), x, 0, pi))
    @test isequal(2, integrate(cos((1//2)*x), x, 0, pi))
    @test isequal(2/y, integrate(sin(x)/y, x, 0, pi))

    @test isequal(2/y, integrate(sinpi(x/pi)/y, x, 0, pi))
    @test isequal(2, integrate(cospi((1//2)*x/pi), x, 0, pi))

    a, b = @syms a b
    @test isequal(((1 - cos(2*a)) / y), integrate(sin(y*x), x, 0, 2a/y))

    unresolved = integrate(x + exp(x), x, 0, 1)
    @test repr(integrate(sin(x^2), x, 0, 1)) == "∫dx[0 to 1](sin(x^2))"
    @test repr(unresolved) == "(1//2) + ∫dx[0 to 1](exp(x))"

    @test isequal(0.5, integrate(sin(x), x, 0, 1; userdb=Dict(sin => x -> x/2)))
    @test isequal(1, integrate(x + sin(x), x, 0, 1; userdb=Dict(sin => x -> x/2)))

    @test isempty(unknownintegrals(integrate(x + sin(x), x, 0, 1)))
    @test repr(only(unknownintegrals(unresolved))) == "∫dx[0 to 1](exp(x))"
    @test repr(only(unknownintegrals(makeintegral(sin(x), x, 0, pi)))) == "∫dx[0 to π](sin(x))"

    @test isequal(2, expandintegrals(makeintegral(sin(x), x, 0, pi)))
    @test repr(expandintegrals(unresolved)) == "(1//2) + ∫dx[0 to 1](exp(x))"
    @test isequal(2.218281828459045, expandintegrals(unresolved; userdb=Dict(exp => exp)))
end

@testset "Symbolics" begin
    x, y = @variables x y
    @test !occursin(2, x)
    @test occursin(unwrap(x), x)
    @test !occursin(unwrap(y), x)
    @test occursin(unwrap(sin(x)), x)
    @test !occursin(unwrap(sin(y)), x)

    @test 2 == integrate(x, x, 0, 2)
    @test isequal(2y, integrate(y, x, 0, 2))
    @test isequal(2y, integrate(y*sin(x), x, 0, pi))
    @test iszero(integrate(sin(x), x, 0, 2pi))
    @test isequal(2(sin(y) + 2), integrate(sin(y)+2, x, 0, 2))
    @test isequal(2y + 2, integrate(x + y, x, 0, 2))
    @test isequal(0, integrate(sin(2x), x, 0, pi))
    @test isequal(2, integrate(cos((1//2)*x), x, 0, pi))
    @test isequal(2/y, integrate(sin(x)/y, x, 0, pi))

    @test isequal(2/y, integrate(sinpi(x/pi)/y, x, 0, pi))
    @test isequal(2, integrate(cospi((1//2)*x/pi), x, 0, pi))

    a, b = @syms a b
    @test isequal(((1 - cos(2*a)) / y), integrate(sin(y*x), x, 0, 2a/y))

    unresolved = integrate(x + exp(x), x, 0, 1)
    @test repr(integrate(sin(x^2), x, 0, 1)) == "Integral(x, 0 .. 1)(sin(x^2))"
    @test repr(unresolved) == "(1//2) + Integral(x, 0 .. 1)(exp(x))"

    @test isequal(0.5, integrate(sin(x), x, 0, 1; userdb=Dict(sin => x -> x/2)))
    @test isequal(1, integrate(x + sin(x), x, 0, 1; userdb=Dict(sin => x -> x/2)))

    @test isempty(unknownintegrals(integrate(x + sin(x), x, 0, 1)))
    @test repr(only(unknownintegrals(unresolved))) == "Integral(x, 0 .. 1)(exp(x))"
    @test repr(only(unknownintegrals(Symbolics.wrap(makeintegral(sin(x), x, 0, pi))))) == "Integral(x, 0.0 .. 3.141592653589793)(sin(x))"

    @test isequal(2, expandintegrals(Symbolics.wrap(makeintegral(sin(x), x, 0, pi))))
    @test repr(expandintegrals(unresolved)) == "(1//2) + Integral(x, 0 .. 1)(exp(x))"
    @test isequal(2.218281828459045, expandintegrals(unresolved; userdb=Dict(exp => exp)))
end
