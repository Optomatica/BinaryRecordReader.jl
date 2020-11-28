using BinaryRecordReader
using Test

BRR = BinaryRecordReader # A convinet shortcut
# First we declare some simple structures 

@testset "Isbits reader" begin
    struct Boo
        x::Int64
        y::Float16
    end

    struct TinyStruct 
        b::Int
    end

    struct MinorStruct 
        a::Int
        c::TinyStruct 
    end


    struct MajorStruct  
        long::Float32
        lat::Float32
        speed::Int16
        COG::UInt16
        time::Int32
        more::MinorStruct
    end

    @test_logs (:warn, "Attempt to create a reader for plain data type Boo") BRR.construct_reader_exp(Boo, NamedTuple())
    @test_logs (:warn, "Attempt to create a reader for plain data type TinyStruct") BRR.construct_reader_exp(TinyStruct, NamedTuple())
    @test_logs (:warn, "Attempt to create a reader for plain data type MinorStruct") BRR.construct_reader_exp(MinorStruct, NamedTuple())
    @test_logs (:warn, "Attempt to create a reader for plain data type MajorStruct") BRR.construct_reader_exp(MajorStruct, NamedTuple())
    @test_logs (:warn, "Attempt to create a reader for plain data type Boo") construct_reader_deep(Boo, NamedTuple())
    @test_logs (:warn, "Attempt to create a reader for plain data type TinyStruct") construct_reader_deep(TinyStruct, NamedTuple())
    @test_logs (:warn, "Attempt to create a reader for plain data type MajorStruct") construct_reader_deep(MajorStruct, NamedTuple())
    @test_logs (:warn, "Attempt to create a reader for plain data type MinorStruct") construct_reader_deep(MinorStruct, NamedTuple())
end;

struct RecHeaderExtended 
    long::Float32
    lat::Float32
    speed::Int16
    COG::UInt16
    time::Int32
    data::Matrix{Int32}
end

@testset "Single Level Reader " begin
    simple_file = tempname()
    n_rec = 1000
    open(simple_file, "w") do io
        for i = 1:n_rec
            if i == 500 # Special write
                write(io, Float32(5), Float32(6), Int16(7), UInt16(8), Int32(9), Int32(4) * ones(Int32, 6, 600))
            else
                write(io, rand(Float32), rand(Float32), rand(Int16), rand(UInt16), rand(Int32), rand(Int32, 6, 600))
            end
        end
    end

    @construct_reader RecHeaderExtended (data = (6, 600),)
    my_data = Vector{RecHeaderExtended}(undef, n_rec)
    read!(simple_file, my_data);
    @test my_data[500].long == 5
    @test my_data[500].lat == 6
    @test my_data[500].speed == 7
    @test my_data[500].COG == 8
    @test my_data[500].time == 9
    @test my_data[500].data == 4 * ones(Int32, 6, 600)
    @test_throws TypeError BRR.construct_reader_exp(RecHeaderExtended, (long = (6, 600),)) 
end;

struct SimpleRec
    lat::Float32
    time::Int32
end

struct CompoundRec
    long::Float32
    COG::UInt16
    data::Matrix{SimpleRec}
end

@testset "Nested Structure Reader " begin
    simple_file = tempname()
    n_rec = 1000
    open(simple_file, "w") do io
        for i = 1:n_rec
            if i == 500 # Special write
                write(io, Float32(5), UInt16(8), [SimpleRec(5, 5) for i = 1:6, y = 1:600])
            else
                write(io, rand(Float32), rand(UInt16), [SimpleRec(rand(Float32), rand(Int32)) for i = 1:6, y = 1:600])
            end
        end
    end

    @construct_reader CompoundRec (data = (6, 600),)
    my_data = Vector{CompoundRec}(undef, n_rec)
    read!(simple_file, my_data);
    @test my_data[500].long == 5
    @test my_data[500].COG == 8
    @test all([x == SimpleRec(5, 5) for x in my_data[500].data])
end;

struct SimpleRecMat
    lat::Float32
    time::Matrix{Int32}
end

struct AnotherSimpleRecMat
    fun::UInt8
    funMat::Matrix{UInt16}
end

struct CompoundRecComplex
    long::Float32
    COG::UInt16
    funky::AnotherSimpleRecMat
    data::Matrix{SimpleRecMat}
end

@testset "Nested Structure Reader with none isbits matrix" begin
    simple_file = tempname()
    n_rec = 1000
    open(simple_file, "w") do io
        for i = 1:n_rec
            if i == 500 # Special write
                write(io, Float32(5), UInt16(8))
                write(io, UInt8(19), UInt16(20) * ones(UInt16, 2, 2))
                for x in 1:6, y in 1:600
                    write(io, Float32(5))
                    write(io, Int32(5) * ones(Int32, 5, 5))  
                end
            else
                write(io, rand(Float32), rand(UInt16))
                write(io, rand(UInt8), rand(UInt16, 2, 2))
                for x in 1:6, y in 1:600
                    write(io, rand(Float32))
                    write(io, rand(Int32, 5, 5)) 
                end
            end
        end
    end

    @test_throws ArgumentError BRR.construct_reader_exp(CompoundRecComplex, (data = (6, 600),)) 
    @test AnotherSimpleRecMat ∉ BRR.def_reads
    eval(:(@construct_reader AnotherSimpleRecMat (funMat = (2, 2),)))
    @test AnotherSimpleRecMat ∈ BRR.def_reads
    @test SimpleRecMat  ∉ BRR.def_reads
    @test_throws ArgumentError BRR.construct_reader_exp(CompoundRecComplex, (data = (6, 600),)) 
    eval(:(@construct_reader SimpleRecMat  (time = (5, 5),)))
    @test SimpleRecMat ∈ BRR.def_reads
    @test_nowarn BRR.construct_reader_exp(CompoundRecComplex, (data = (6, 600),)) 
    eval(:(@construct_reader CompoundRecComplex (data = (6, 600),)))
    my_data = Vector{CompoundRecComplex}(undef, n_rec)
    read!(simple_file, my_data);
    @test my_data[500].long == 5
    @test my_data[500].COG == 8
    @test my_data[500].funky.fun == 19
    @test all(my_data[500].funky.funMat .== 20)
    @test all([x.lat == 5 && all(x.time .== 5) for x in my_data[500].data])
end;

struct C
    lat::Float32
    time::Matrix{Int32}
end

struct B
    fun::UInt8
    funMat::Matrix{UInt16}
end

struct A
    long::Float32
    COG::UInt16
    funky::B
    data::Matrix{C}
end

@testset "Nested Structure Reader we internal methods" begin
    simple_file = tempname()
    n_rec = 1000
    open(simple_file, "w") do io
        for i = 1:n_rec
            if i == 500 # Special write
                write(io, Float32(5), UInt16(8))
                write(io, UInt8(19), UInt16(20) * ones(UInt16, 2, 2))
                for x in 1:6, y in 1:600
                    write(io, Float32(5))
                    write(io, Int32(5) * ones(Int32, 5, 5))  
                end
            else
                write(io, rand(Float32), rand(UInt16))
                write(io, rand(UInt8), rand(UInt16, 2, 2))
                for x in 1:6, y in 1:600
                    write(io, rand(Float32))
                    write(io, rand(Int32, 5, 5)) 
                end
            end
        end
    end
    # strip array test 
    @test BRR.strip_array_specs(A,(data=(5,5), B__funMat=(2,2), C__time =(3,3))) == (Dict(:data => (5,5)), [:B, :C])
    @test BRR.strip_array_specs(B,(data=(5,5), B__funMat=(2,2), C__time =(3,3))) == (Dict(:funMat => (2,2), :data => (5,5)), [:C])
    @test BRR.strip_array_specs(C,(data=(5,5), B__funMat=(2,2), C__time =(3,3))) == (Dict(:data => (5,5), :time=>(3,3)),  [:B])
    @test_throws ArgumentError construct_reader_shallow(A, (data = (6, 600),)) 
    @test B ∉ BRR.def_reads
    @test C ∉ BRR.def_reads
    @test_throws ArgumentError construct_reader_deep(A, (data = (6, 600),)) 
    @test_throws ArgumentError construct_reader_deep(A, (data = (6, 600),)) 
    @test_throws TypeError construct_reader_deep(A, (long = (6, 600),)) 
    @test_nowarn construct_reader_shallow(C,(time =(2,2),))    
    @test_nowarn construct_reader_deep(A,(data=(6,600), B__funMat=(2,2), C__time =(5,5)))    
    my_data = Vector{A}(undef, n_rec)
    read!(simple_file, my_data);
    @test my_data[500].long == 5
    @test my_data[500].COG == 8
    @test my_data[500].funky.fun == 19
    @test all(my_data[500].funky.funMat .== 20)
    @test all([x.lat == 5 && all(x.time .== 5) for x in my_data[500].data])
end;