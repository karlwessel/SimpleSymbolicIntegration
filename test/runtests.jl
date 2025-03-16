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

    intx0to2(p; userdb=Dict()) = integrate(p, x, 0, 2; userdb)
    intx0topi(p; userdb=Dict()) = integrate(p, x, 0, pi; userdb)

    @test !occursin(2, x)
    @test occursin(x, x)
    @test !occursin(y, x)
    @test occursin(sin(x), x)
    @test !occursin(sin(y), x)

    @test 2 == intx0to2(x)
    @test isequal(0.5, intx0topi(x/pi^2))
    @test isequal(2y, intx0to2(y))
    @test isequal(2y, intx0topi(y*sin(x)))
    @test isequal(log(2), integrate(1/x, x, 1, 2))

    # integrands containing products
    @test isequal(log(2) - 4, integrate((x+1)*(1/x - 2), x, 1, 2))
    @test isapprox(1//2 - log(4), integrate(((x+1)*(x - 2)) / x, x, 1, 2))
    @test isequal(log(2) + 1, integrate((x+1)/x, x, 1, 2))
    @test isequal(log(4) + 2, integrate((2(x+1))/x, x, 1, 2))
    
    # complex integrands
    @test isequal(2y*im, intx0topi(im*y*sin(x)))
    @test isequal(1//2 + 2y*im, intx0topi(x/pi^2 + im*y*sin(x)))
    @test isequal(1//2*y + 2y*im, intx0topi(y*(x/pi^2 + im*sin(x))))
    
    @test iszero(integrate(sin(x), x, 0, 2pi))
    @test isequal(2, intx0topi(sin(x)))
    @test isequal(2(sin(y) + 2), intx0to2(sin(y)+2))
    @test isequal(2y + 2, intx0to2(x + y))
    @test isequal(0, intx0topi(sin(2x)))
    @test isequal(2, intx0topi(cos((1//2)*x)))
    @test isequal(2/y, intx0topi(sin(x)/y))

    @test isequal(2/y, intx0topi(sinpi(x/pi)/y))
    @test isequal(2, intx0topi(cospi((1//2)*x/pi)))

	# symbolic limits
    a, b = @syms a b
    @test isequal(((1 - cos(2*a)) / y), integrate(sin(y*x), x, 0, 2a/y))

	# unresolved integrals
    unresolved = intx0to2(x + exp(x))
    @test repr(intx0to2(sin(x^2))) == "∫dx[0 to 2](sin(x^2))"
    @test repr(intx0to2(1/sin(x))) == "∫dx[0 to 2](1 / sin(x))"
    @test repr(intx0to2(sin(x)/x)) == "∫dx[0 to 2](sin(x) / x)"
    @test repr(unresolved) == "(2//1) + ∫dx[0 to 2](exp(x))"

	# resolve integrals using userdb
    @test isequal(1, intx0to2(sin(x); userdb=Dict(sin => x -> x/2)))
    @test isequal(3, intx0to2(x + sin(x); userdb=Dict(sin => x -> x/2)))

	# unknownintegrals
    @test isempty(unknownintegrals(intx0to2(x + sin(x))))
    @test repr(only(unknownintegrals(unresolved))) == "∫dx[0 to 2](exp(x))"
    @test repr(only(unknownintegrals(makeintegral(sin(x), x, 0, pi)))) == "∫dx[0 to π](sin(x))"
    # unknownintegrals for complex integrands
    @test repr(only(unknownintegrals(makeintegral(im*sin(x), x, 0, pi)))) == "∫dx[0 to π]((im)*sin(x))"

	# expandintegrals
    @test isequal(2, expandintegrals(makeintegral(sin(x), x, 0, pi)))
    @test isequal(4, expandintegrals(makeintegral(makeintegral(sin(x), x, 0, pi), x, 0, 2)))
    @test repr(expandintegrals(unresolved)) == "(2//1) + ∫dx[0 to 2](exp(x))"
    # expandintegrals with complex integrand
    @test isequal(2im, expandintegrals(makeintegral(im*sin(x), x, 0, pi)))
    @test isequal(4im, expandintegrals(makeintegral(makeintegral(im*sin(x), x, 0, pi), x, 0, 2)))
    @test isequal(1 + 4im, expandintegrals(makeintegral(makeintegral(x/pi^2 + im*sin(x), x, 0, pi), x, 0, 2)))
    # expandintegrals with userdb
    @test isequal(8.38905609893065, expandintegrals(unresolved; userdb=Dict(exp => exp)))
end

@testset "Symbolics" begin
    x, y = @variables x y

    intx0to2(p; userdb=Dict()) = integrate(p, x, 0, 2; userdb)
    intx0topi(p; userdb=Dict()) = integrate(p, x, 0, pi; userdb)

    @test !occursin(2, x)
    @test occursin(unwrap(x), x)
    @test !occursin(unwrap(y), x)
    @test occursin(unwrap(sin(x)), x)
    @test !occursin(unwrap(sin(y)), x)

    @test 2 == intx0to2(x)
    @test isequal(2y, intx0to2(y))
    @test isequal(2y, intx0topi(y*sin(x)))

    # complex integrand
    @test isequal(2y*im, intx0topi(im*y*sin(x)))
    @test isequal(1//2 + 2y*im, intx0topi(x/pi^2 + im*y*sin(x)))
    @test isequal(1//2*y + 2y*im, intx0topi(y*(x/pi^2 + im*sin(x))))

    @test iszero(integrate(sin(x), x, 0, 2pi))
    @test isequal(2(sin(y) + 2), intx0to2(sin(y)+2))
    @test isequal(2y + 2, intx0to2(x + y))
    @test isequal(0, intx0topi(sin(2x)))
    @test isequal(2, intx0topi(cos((1//2)*x)))
    @test isequal(2/y, intx0topi(sin(x)/y))
    @test isequal(log(2), integrate(1/x, x, 1, 2))

    # integrands containing products
    @test isequal(log(2) - 4, integrate((x+1)*(1/x - 2), x, 1, 2))

    @test isequal(2/y, intx0topi(sinpi(x/pi)/y))
    @test isequal(2, intx0topi(cospi((1//2)*x/pi)))

	# symbolic limits
    a, b = @syms a b
    @test isequal(((1 - cos(2*a)) / y), integrate(sin(y*x), x, 0, 2a/y))

	# unresolved integrals
    unresolved = intx0to2(x + exp(x))
    @test repr(intx0to2(sin(x^2))) == "Integral(x, 0 .. 2)(sin(x^2))"
    @test repr(unresolved) == "(2//1) + Integral(x, 0 .. 2)(exp(x))"
	# solve using userdb
    @test isequal(1, intx0to2(sin(x); userdb=Dict(sin => x -> x/2)))
    @test isequal(3, intx0to2(x + sin(x); userdb=Dict(sin => x -> x/2)))

	# unknownintegrals
    @test isempty(unknownintegrals(intx0to2(x + sin(x))))
    @test repr(only(unknownintegrals(unresolved))) == "Integral(x, 0 .. 2)(exp(x))"
    @test repr(only(unknownintegrals((makeintegral(sin(x), x, 0, pi))))) == "Integral(x, 0.0 .. 3.141592653589793)(sin(x))"
    # complex integrand
    @test repr(only(unknownintegrals(intx0to2(im*exp(x))))) == "Integral(x, 0 .. 2)(exp(x))"

	# expandintegrals
    @test isequal(2, expandintegrals(makeintegral(sin(x), x, 0, pi)))
    @test isequal(4, expandintegrals(makeintegral(makeintegral(sin(x), x, 0, pi), x, 0, 2)))
    @test repr(expandintegrals(unresolved)) == "(2//1) + Integral(x, 0 .. 2)(exp(x))"
    # complex integrand
    @test isequal(2im, expandintegrals(makeintegral(im*sin(x), x, 0, pi)))
    @test isequal(2im, expandintegrals(Integral(x in (0, pi))(im*sin(x))))
    @test isequal(4im, expandintegrals(makeintegral(makeintegral(im*sin(x), x, 0, pi), x, 0, 2)))
    @test isequal(1 + 4im, expandintegrals(makeintegral(makeintegral(x/pi^2 + im*sin(x), x, 0, pi), x, 0, 2)))
    # expandintegrals with userdb
    @test isequal(8.38905609893065, expandintegrals(unresolved; userdb=Dict(exp => exp)))
end
