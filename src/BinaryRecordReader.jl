module BinaryRecordReader

using MacroTools

export @construct_reader, construct_reader_deep, construct_reader_shallow

global const def_reads=Set{DataType}()

macro construct_reader(Struct, dims)
    array_specs = eval(dims)
    s = eval(:($__module__.$Struct))
    esc(construct_reader_exp(s,array_specs))
end


"""
    @construct_reader S array_specs

Generates a `Base.read(io::IOStream, ::Type{S})` method that can used read type `S`, which is not an `isbitstype`. 

# Example
```julia-repl
julia> struct CompoundStruct
           long::Float32
           COG::UInt16
           data::Matrix{Float64}
       end
julia> @construct_reader CompoundStruct (data=(10,10),)
```
The above will generate a suitable `read` method assuming that the `data` field is a 10x10 matrix. 

See also: `construct_reader_deep`, `@construct_reader`
"""
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

function strip_array_specs(s, array_specs)
    a = Dict{Symbol,Tuple}()
    for k in keys(array_specs)
        parts=split(string(k),"__")
        length(parts) == 1 && (a[k] = array_specs[k])
        parts[1] == string(s) && (a[Symbol(parts[2])] = array_specs[k])
    end
    a
end

"""
    construct_reader_shallow(S,array_specs)

Generates a `Base.read(io::IOStream, ::Type{S})` method that can used read type `S`, which is not an `isbitstype`. 
The named tuble, `array_spec`, is used to define the dimensionality of the field in question. 

# Example
```julia-repl
julia> struct CompoundStruct
           long::Float32
           COG::UInt16
           data::Matrix{Float64}
       end
julia> construct_reader_shallow(CompoundStruct, (data=(10,10),))
```
The above will generate a suitable `read` method assuming that the `data` field is a 10x10 matrix. 

See also: `construct_reader_deep`, `@construct_reader`
"""
function construct_reader_shallow(s, array_specs)
    eval(construct_reader_exp(s, array_specs))
end

"""
    construct_reader_deep(S,array_specs)

Generates a `Base.read(io::IOStream, ::Type{S})` method that can used read type `S`, which is not an `isbitstype`. 
If the class in question has other fields that made of up of other non-`isbitstype`s a full specification put in place 
in the `array_spec`. The syntax for   `types` is `SubTypeName__fieldname`. 

# Example
```julia-repl
julia> struct C
            lat::Float32
            time::Matrix{Int32}
        end
julia> struct B
            fun::UInt8
            funMat::Matrix{UInt16}
        end
julia> struct A
            long::Float32
            COG::UInt16
            funky::AnotherSimpleRecMat
            data::Matrix{SimpleRecMat}
        end

julia> construct_reader_deep(A, (data=(5,5), B__funMat=(2,2), C_time =(3,3)))

```
The above will generate three `read` methods for all the three types defined. 

See also: `construct_reader_shallow`, `@construct_reader`
"""
function construct_reader_deep(s, array_specs)
    isbitstype(s) && (@warn("Attempt to create a reader for plain data type $s"); return nothing) # short ciruite for isbitstype
    a = strip_array_specs(s, array_specs)
    for (f,t) in  zip(fieldnames(s), fieldtypes(s))
        if haskey(a,f)
            t <: Array || throw(TypeError(:construct_reader_exp, "construction of intenral reader", Array,t))
            et = eltype(t)
            if !isbitstype(et) && et ∉ def_reads 
               construct_reader_deep(et,array_specs)
            end
        else
            isbitstype(t) || t ∈ def_reads || t <: Array && throw(ArgumentError("$t has no properly defined read function"))
            if !isbitstype(t) && t ∉ def_reads 
               construct_reader_deep(t,array_specs)
            end
        end
    end
    eval(construct_reader_exp(s,a))
end

end
