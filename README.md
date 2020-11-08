# BinaryRecordReader

[![Build Status](https://travis-ci.com/Optomatica/BinaryRecordReader.jl.svg?branch=master)](https://travis-ci.com/Optomatica/BinaryRecordReader.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/fhpn75k3r67ow3ke/branch/master?svg=true)](https://ci.appveyor.com/project/mbeltagy/binaryrecordreader-jl/branch/master)
[![Coverage](https://codecov.io/gh/Optomatica/BinaryRecordReader.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Optomatica/BinaryRecordReader.jl)

This package allow for the convient description for the structure of binary files. It creates a `read` method that can then be used to read and binary file that follows the described structure. 

Example usage 
```julia
using BinaryRecordReader


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
