using SimpleSymbolicIntegration
using Test
using SymbolicUtils
import SimpleSymbolicIntegration: occursin

@testset "integral" begin
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
    @test isequal(2(sin(y) + 2), integrate(sin(y)+2, x, 0, 2))
    @test isequal(2y + 2, integrate(x + y, x, 0, 2))
    @test_broken isequal(0, integrate(sin(2x), x, 0, pi))
    @test_broken isequal(2, integrate(cos((1//2)*x), x, 0, pi))
    @test isequal(2/y, integrate(sin(x)/y, x, 0, pi))

    @test_broken isequal(2/y, integrate(sinpi(x/pi)/y, x, 0, pi))
    @test_broken isequal(2, integrate(cospi((1//2)*x/pi), x, 0, pi))

    a, b = @syms a b
    @test_broken isequal(((1 - cos(2*a)) / y), integrate(sin(y*x), x, 0, 2a/y))
end
