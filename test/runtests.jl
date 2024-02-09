using DLFP8Types
using Test

@testset "DLFP8Types.jl" begin
    for FP8 in (Float8_E4M3FN, Float8_E4M3FNUZ, Float8_E5M2, Float8_E5M2FNUZ)
        name = String(nameof(FP8))
        @testset "$name" begin
            # torch_fp8 = name2torchtype(name)
            # write("$name.bin", torch.arange(0, 256, dtype=torch.uint8).view(torch_fp8).type(torch.float32).numpy())
            # write("$(name)_U8.bin", torch.arange(0, 256, dtype=torch.uint8).view(torch_fp8).type(torch.float32).type(torch_fp8).view(torch.uint8).numpy())
            real_bytes = reinterpret(Float32, read(joinpath(@__DIR__, "$name.bin")))
            real_bytes_from32 = read(joinpath(@__DIR__, "$(name)_U8.bin"))
            for (i, byte) in enumerate(typemin(UInt8):typemax(UInt8))
                real_float = real_bytes[i]
                real_byte32 = reinterpret(UInt32, real_float)
                real_byte = real_bytes_from32[i]
                real_fp8 = reinterpret(FP8, real_byte)
                fp8 = reinterpret(FP8, byte)
                test_float = Float32(fp8)
                test_byte32 = reinterpret(UInt32, test_float)
                test_fp8 = FP8(test_float)
                test_byte = reinterpret(UInt8, test_fp8)
                @test isequal(test_float, real_float)
                @test test_byte32 == real_byte32 || (isnan(test_float) && isnan(real_float))
                @test isequal(test_fp8, real_fp8)
                @test test_byte == real_byte
                @test byte == test_byte || isnan(fp8)
            end
            all_bytes = reinterpret.(FP8, typemin(UInt8):typemax(UInt8))
            @test one(FP8) == FP8(1)
            @test iszero(zero(FP8))
            @test count(iszero, all_bytes) == (iszero(-zero(FP8)) ? 2 : 1)
            @test count(isnan, all_bytes) == (FP8 == Float8_E4M3FN ? 2 : FP8 == Float8_E5M2 ? 6 : 1)
            @test count(isinf, all_bytes) == (FP8 == Float8_E5M2 ? 2 : 0)
            @test count(isfinite, all_bytes) == length(all_bytes) - count(isinf, all_bytes) - count(isnan, all_bytes)
            @test count(issubnormal, all_bytes) == 2 * (2 ^ Base.significand_bits(FP8) - 1)
            sorted = unique!(filter(!isnan, sort(all_bytes)))
            @test foldl(1:256; init=[typemax(FP8)]) do xs, _
                x = xs[begin]
                nx = prevfloat(x)
                x != nx && pushfirst!(xs, nx)
                return xs
            end == sorted
            @test foldl(1:256; init=[typemin(FP8)]) do xs, _
                x = xs[end]
                nx = nextfloat(x)
                x != nx && push!(xs, nx)
                return xs
            end == sorted
            @test foldl(1:128; init=[typemax(FP8)]) do xs, _
                x = xs[begin]
                nx = prevfloat(x, 1)
                nx2 = prevfloat(x, 2)
                x != nx && pushfirst!(xs, nx)
                nx != nx2 && pushfirst!(xs, nx2)
                return xs
            end == sorted
            @test foldl(1:128; init=[typemin(FP8)]) do xs, _
                x = xs[end]
                nx = nextfloat(x)
                nx2 = nextfloat(x, 2)
                x != nx && push!(xs, nx)
                nx != nx2 && push!(xs, nx2)
                return xs
            end == sorted
        end
    end
end
