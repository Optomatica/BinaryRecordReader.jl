using BinaryRecReader
using Test

# First we declare some simple structures 

struct Boo
    x::Int64
    y::Float16
end

@testset "Simple Read" begin
    simple_file=tempname()
    n_rec=1000
    open(simple_file,"w") do io
        for i=1:n_rec
            if i==500 #Special write
                write(io,Ref(Boo(123,123)))
            else
                write(io,Ref(Boo(i,55)))
            end
        end
    end
    @construct_reader Boo
    my_data=Vector{Boo}(undef,n_rec)
    read!(simple_file,my_data);
    @test my_data[500].x == 123
    @test my_data[500].y == Float16(123)
end;
