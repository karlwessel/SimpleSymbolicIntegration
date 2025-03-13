function occursin(p, x)
    isequal(p, x) && return true

    !iscall(p) && return false
    for a in arguments(p)
        occursin(a, x) && return true
    end
    return false
end

occursin(p::Number, x) = isequal(p, x)

function integrate(p, iv, from, to)
    hasx(p) = occursin(p, iv)
    Integ(y) = integrate(y, iv, from, to)
    integterm(y) = maketerm(typeof(p), integrate, [y, iv, from, to], metadata(p))

    !hasx(p) && return p*(to - from)
    if !iscall(p)
        isequal(p, iv) && return 1//2*(to^2 - from^2)
    else
        intmap = Dict([cos => sin,
            sin => x -> -cos(x),
            cospi => x -> sinpi(x) / pi,
            sinpi => x -> -cospi(x) / pi])

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
            isequal(y, iv) && return antideriv(to) - antideriv(from)
        end
    end

    return integterm(p)
end
