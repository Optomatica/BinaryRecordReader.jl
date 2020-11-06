# BinaryRecReader

[![Build Status](https://travis-ci.com/mbeltagy/BinaryRecReader.jl.svg?branch=master)](https://travis-ci.com/mbeltagy/BinaryRecReader.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/mbeltagy/BinaryRecReader.jl?svg=true)](https://ci.appveyor.com/project/mbeltagy/BinaryRecReader-jl)
[![Coverage](https://codecov.io/gh/mbeltagy/BinaryRecReader.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mbeltagy/BinaryRecReader.jl)
[![Coverage](https://coveralls.io/repos/github/mbeltagy/BinaryRecReader.jl/badge.svg?branch=master)](https://coveralls.io/github/mbeltagy/BinaryRecReader.jl?branch=master)

This package allow for the convient description for the structure of binary files. It creates a `read` method that can then be used to read and binary file that follows the described structure. 

Example usage 
```julia
using BinaryRecReader


struct TestS
    a::Int16
    b::Float64
    m::Vector{Int32}
    k::UInt8 
end

@construct_reader TestS (m=(500,1)) 

myrecs=Vector{TestS}(undef,15)
read!("somefile.txt",myrecs)
```
