module BinaryRecReader

using MacroTools

export @construct_reader

macro construct_reader(Struct, dims)
    expr = quote
        function Base.read(io::IOStream, ::Type{$Struct})
        end
    end|> prettify
    array_specs=eval(dims)
    s = eval(Struct)
    for (f,t) in  zip(fieldnames(s), fieldtypes(s))
        if haskey(array_specs,f)
            push!(expr.args[2].args, :($f = read!(io,$t(undef, $(array_specs[f])))))
        else
            push!(expr.args[2].args, :($f = read(io, $t)))
        end
    end
    fields = [f for f in fieldnames(s)]
    push!(expr.args[2].args, Expr(:call,Struct,fields...))
    expr
end


macro construct_reader(Struct)
    :(@construct_reader $Struct NamedTuple())
end

end
