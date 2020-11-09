# BinaryRecordReader

[![Build Status](https://travis-ci.com/Optomatica/BinaryRecordReader.jl.svg?branch=master)](https://travis-ci.com/Optomatica/BinaryRecordReader.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/fhpn75k3r67ow3ke/branch/master?svg=true)](https://ci.appveyor.com/project/mbeltagy/binaryrecordreader-jl/branch/master)
[![Coverage](https://codecov.io/gh/Optomatica/BinaryRecordReader.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Optomatica/BinaryRecordReader.jl)

This package allow for the convenient description for the structure of binary records. It creates a `read` method that can be used to read the specified records from binary file. 

Example usage 
```julia
using BinaryRecordReader


struct TestS
    a::Int16
    b::Float64
    m::Vector{Int32}
    k::UInt8 
end

@construct_reader TestS (m=(500,),) 
```

The first argument to the `@construct_reader` macro is the type we wish to generate a `read` method for, the second argument is a [NameTuple](https://docs.julialang.org/en/v1/manual/types/#Named-Tuple-Types) to specify the dimensionality of the field names that require explicit definition. 

In the above example, `@construct_reader` macro will construct a `Base.read` method for the `TestS` type with the size of the `m` having 500 elements. Concretely, the generated code will be:  

```julia
function Base.read(io::IOStream, ::Type{TestS})
      a = read(io, Int16)
      b = read(io, Float64)
      m = read!(io, (Array{Int32,1})(undef, (500, 1)))
      k = read(io, UInt8)
      TestS(a, b, m, k)
  end
```

The generated `read` function can be explicitly called, as in 

```julia
file_name="some_binary_file.dat"
open(file_name) do io
    read(io,TestS)
end
```
or implicitly, via `read!` while filling up an array, as in 

```julia
myrecs=Vector{TestS}(undef,15)
read!(file_name,myrecs)
```
