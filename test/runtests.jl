using BinaryRecReader
using Test

# First we declare some simple structures 
struct Boo
    x::Int64
    y::Float16
end

simple_file=tempname()
open(simple_file,"w") do io
    for i=1:1000
        if i==500 #Special write
            write(io,123,Float64(123))
        else
            write(io,rand(Int64),rand(Float16))
        end
    end
end

@testset "Simple Read" begin
    # Write your tests here.
end
