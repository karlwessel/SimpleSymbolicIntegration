function occursin(p, x)
    isequal(p, x) && return true

    !iscall(p) && return false
    for a in arguments(p)
        occursin(a, x) && return true
    end
    return false
end

makederivative(y, iv, metadata=metadata(y)) = maketerm(typeof(y), simplederivative, [y, iv], metadata)

"""
    simplederivative(term, iv)

Only implements derivatives to the point where it is able to derive all
expressions whose derivative is constant with respect to the variable to
derive for.

This is used to handle integrals of functions whichs arguments are linear in
the integration variable. For example ``sin(2x+3)``.
"""
function simplederivative(y, iv)
    !occursin(y, iv) && return zero(y)
    if iscall(y)
        D(x) = simplederivative(x, iv)
        op = operation(y)
        if op == +
            return +(map(D, arguments(y))...)
        elseif op == *
            if arity(y) == 2
                a, b = arguments(y)
                return a*D(b) + D(a)*b
            else
                @assert arity(y) > 2
                args = arguments(y)
                a, others = first(args), *(args[begin+1:end]...)
                return a * D(others) + D(a)*others
            end
        end
    else
        return isequal(y, iv) ? one(y) : zero(y)
    end
    return makederivative(y, iv)
end

makeintegral(symtype, y, iv, lower, upper, metadata=metadata(y)) = maketerm(symtype, integrate, [y, iv, lower, upper], metadata)

occursin(p::Number, x) = isequal(p, x)

integraldb = Dict([cos => sin,
            sin => x -> -cos(x),
            cospi => x -> sinpi(x) / pi,
            sinpi => x -> -cospi(x) / pi])

"""
    integrate(integrand, iv, lower_bound, upper_bound; userdb=Dict())

Calculate the integral of `integrand` over `iv` from `lower_bound` to `upper_bound`.

User defined indefinite integrals of a function can be passed via `userdb`. For
example to define the indefinite integral of ``sin(x)`` one would pass
`userdb=Dict(sin => x -> -cos(x))`.
"""
function integrate(p, iv, lower, upper; userdb=Dict(), symtype=typeof(p))
    hasx(p) = occursin(p, iv)
    Integ(y) = integrate(y, iv, lower, upper; userdb, symtype)
    integterm(y) = makeintegral(symtype, y, iv, lower, upper)

    !hasx(p) && return p*(upper - lower)
    if !iscall(p)
        isequal(p, iv) && return 1//2*(upper^2 - lower^2)
    else
        intmap = merge(integraldb, userdb)

        op = operation(p)
        if op == *
            args = arguments(p)
            withxidx = hasx.(args)
            argswithx = args[withxidx]
            argswithoutx = args[(.!)(withxidx)]
            if length(argswithx) > 1
                return *(integterm(*(argswithx...)), argswithoutx...)
            end
            return *(Integ(only(argswithx)), argswithoutx...)
        elseif op == /
            nom, denom = arguments(p)
            if !hasx(denom)
                return Integ(nom) / denom
            end
        elseif op == +
            return sum(map(Integ, arguments(p)))
        elseif haskey(intmap, op)
            y = only(arguments(p))
            antideriv = intmap[op]
            dy = simplederivative(y, iv)
            if !hasx(dy)
                return (antideriv(substitute(y, Dict(iv => upper))) - antideriv(substitute(y, Dict(iv => lower)))) / dy
            end
        end
    end

    return integterm(p)
end
