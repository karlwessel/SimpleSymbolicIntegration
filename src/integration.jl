struct Integral
    iv
    lower
    upper
end

(i::Integral)(x; userdb=Dict()) = integrate(x, i.iv, i.lower, i.upper; userdb)

Base.show(io::IO, i::Integral) = print(io, "∫d$(i.iv)[$(i.lower) to $(i.upper)]")
SymbolicUtils.show_call(io::IO, i::Integral, args) = print(io, "∫d$(i.iv)[$(i.lower) to $(i.upper)]($(only(args)))")

function occursin(p, x)
    if iscall(p)
        return any(occursin(a, x) for a in arguments(p))
    else
        return isequal(p, x)
    end
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

makeintegral(y, iv, lower, upper, metadata=metadata(y)) = maketerm(typeof(y), Integral(iv, lower, upper), [y], metadata)

occursin(p::Number, x) = isequal(p, x)

const integraldb::Dict{Function, Function} = Dict([cos => sin,
            sin => x -> -cos(x),
            cospi => x -> sinpi(x) / pi,
            sinpi => x -> -cospi(x) / pi])

isintegral(ex) = operation(ex) isa Integral

"""
    unknownintegrals(expression)

Return all unique integrals in the passed expression.
"""
function unknownintegrals(ex)
    if iscall(ex)
        unknown = vcat(map(unknownintegrals, arguments(ex))...)
        if isintegral(ex)
            push!(unknown, ex)
        end
        return unique(unknown)
    end
    return []
end

"""
    expandintegrals(expression)

Try to integrate all integrals in the passed expression.

User defined indefinite integrals of a function can be passed via `userdb`. For
example to define the indefinite integral of ``sin(x)`` one would pass
`userdb=Dict(sin => x -> -cos(x))`.
"""
function expandintegrals(ex; userdb=Dict())
    localexpand(x) = expandintegrals(x; userdb)
    if iscall(ex)
        op = operation(ex)
        args = map(localexpand, arguments(ex))
        if isintegral(ex)
            ex = op(args...; userdb)
        else
            ex = op(args...)
        end
    end
    return ex
end

terms(x) = iscall(x) && (operation(x) == +) ? arguments(x) : [x]

function splitprod(x, hasx)
    (!iscall(x) || operation(x) != *) && return hasx(x) ? ([x], 1) : ([], x)

    args = arguments(x)
    withxidx = hasx.(args)
    argswithx = args[withxidx]
    argswithoutx = args[(.!)(withxidx)]
    c = isempty(argswithoutx) ? 1 : *(argswithoutx...)
    return argswithx, c
end

function expandprod(x, hasx)
    argswithx, c = splitprod(x, hasx)

    isempty(argswithx) && return [], c
    ts = terms.(argswithx)
    return Iterators.product(ts...), c
end

"""
    integrate(integrand, iv, lower_bound, upper_bound; userdb=Dict())

Calculate the integral of `integrand` over `iv` from `lower_bound` to `upper_bound`.

User defined indefinite integrals of a function can be passed via `userdb`. For
example to define the indefinite integral of ``sin(x)`` one would pass
`userdb=Dict(sin => x -> -cos(x))`.
"""
function integrate(p, iv, lower, upper; userdb=Dict())
    hasx(p) = occursin(p, iv)
    Integ(y) = integrate(y, iv, lower, upper; userdb)
    integterm(y) = makeintegral(y, iv, lower, upper)

    !hasx(p) && return p*(upper - lower)
    if !iscall(p)
        isequal(p, iv) && return 1//2*(upper^2 - lower^2)
    else
        op = operation(p)
        if op == *
            # prod(fi(x) + ci)*c
            ts, c = expandprod(p, hasx)
            if length(ts) == 1
                facs = only(ts)
                if length(facs) == 1
                    return c*Integ(only(facs))
                else
                    return c*integterm(prod(facs))
                end
            else
                return c*sum(Integ.(prod.(ts)))
            end
        elseif op == /
            nom, denom = arguments(p)
            fsd, cd = splitprod(denom, hasx)
            if isempty(fsd)
                # f(x) / const
                return Integ(nom) / cd
            else
                gofx = prod(fsd)
                fsn, cn = splitprod(nom, hasx)
                if isempty(fsn)
                    # cn / (g(x)*cd)
                    if isequal(gofx, iv)
                        # const / x*cd
                        return cn / cd * (log(abs(upper)) - log(abs(lower)))
                    else
                        return cn / cd * integterm(1/gofx)
                    end
                else
                    # f(x)*cn / (g(x)*cd)
                    ts = Iterators.product(terms.(fsn)...)
                    if length(ts) == 1
                        return cn / cd * integterm(prod(only(ts)) / gofx)
                    else
                        return cn / cd * sum(Integ.(prod.(ts) ./ gofx))
                    end
                end
            end
        elseif op == +
            return sum(map(Integ, arguments(p)))
        else
            intmap = merge(integraldb, userdb)
            if haskey(intmap, op)
                y = only(arguments(p))
                antideriv = intmap[op]
                dy = simplederivative(y, iv)
                if !hasx(dy)
                    return (antideriv(substitute(y, Dict(iv => upper))) - antideriv(substitute(y, Dict(iv => lower)))) / dy
                end
            end
        end
    end

    return integterm(p)
end
