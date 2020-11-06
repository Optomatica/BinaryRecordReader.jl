module BinaryRecReader

using MacroTools

export @construct_reader

macro construct_reader(Struct, dims)
    array_specs = eval(dims)
    s = eval(:($__module__.$Struct))
    esc(construct_reader_exp(Struct,s,array_specs))
end


macro construct_reader(Struct)
    s = eval(:($__module__.$Struct))
    esc(construct_reader_exp(Struct,s,NamedTuple()))
end

function construct_reader_exp(Struct, s, array_specs)
    expr = quote
        function Base.read(io::IOStream, ::Type{$Struct})
    end end |> prettify
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

end
