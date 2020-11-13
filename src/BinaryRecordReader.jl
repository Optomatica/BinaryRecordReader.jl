module BinaryRecordReader

using MacroTools

export @construct_reader

global const def_reads=Set{DataType}()

macro construct_reader(Struct, dims)
    array_specs = eval(dims)
    s = eval(:($__module__.$Struct))
    esc(construct_reader_exp(s,array_specs))
end


macro construct_reader(Struct)
    esc(:(@construct_reader $Struct NamedTuple()))
end

function construct_reader_exp(s, array_specs)
    isbitstype(s) && (@warn("Attempt to create a reader for plain data type $s"); return nothing) # short ciruite for isbitstype
    expr = quote
        function Base.read(io::IOStream, ::Type{$s})
    end end |> prettify
    for (f,t) in  zip(fieldnames(s), fieldtypes(s))
        if haskey(array_specs,f)
            t <: Array || throw(TypeError(:construct_reader_exp, "construction of intenral reader", Array,t))
            et = eltype(t)
            isbitstype(et) || et ∈ def_reads || throw(ArgumentError("Array element $et has no properly defined read function"))
            push!(expr.args[2].args, :($f = read!(io,$t(undef, $(array_specs[f])))))
        else
            isbitstype(t) || t ∈ def_reads || throw(ArgumentError("$t has no properly defined read function"))
            push!(expr.args[2].args, :($f = read(io, $t)))
        end
    end
    fields = [f for f in fieldnames(s)]
    push!(expr.args[2].args, Expr(:call,s,fields...))
    push!(def_reads,s) #marking it as defined
    expr
end

end
