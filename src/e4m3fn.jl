# https://github.com/pytorch/pytorch/blob/e9907a344605f44bfe8d1b760f8f5859c1bc4b44/c10/util/Float8_e4m3fn.h
function Float8_E4M3FN(float::Float32)
    fp8_max = UInt32(1087) << UInt32(20)
    denorm_mask = UInt32(141) << UInt32(23)
    f_bits = reinterpret(UInt32, float)
    sign = f_bits & Base.sign_mask(Float32)
    f_bits ⊻= sign
    result = zero(UInt8)
    if f_bits >= fp8_max
        result = 0x7f
    else
        if f_bits < (UInt32(121) << UInt32(23))
            f_bits = reinterpret(UInt32, reinterpret(Float32, f_bits) + reinterpret(Float32, denorm_mask))
            result = (f_bits - denorm_mask) % UInt8
        else
            mant_odd = (f_bits >> UInt32(20)) & 0x1
            f_bits += 0xc407ffff # reinterpret(UInt32, Int32(7 - 127)) << 23 + 0x7ffff
            f_bits += mant_odd
            result = (f_bits >> UInt32(20)) % UInt8
        end
    end
    result |= (sign >> UInt32(24)) % UInt8
    return bitcast(Float8_E4M3FN, result)
end

function Base.Float32(fp8::Float8_E4M3FN)
    w = UInt32(reinterpret(UInt8, fp8)) << UInt32(24)
    sign = w & Base.sign_mask(Float32)
    nonsign = w & ~Base.sign_mask(Float32)
    renorm_shift = UInt32(leading_zeros(nonsign))
    renorm_shift = renorm_shift > 0x4 ? renorm_shift - 0x4 : zero(UInt32)
    inf_nan_mask = ((reinterpret(Int32, nonsign + 0x01000000) >> Int32(8)) & reinterpret(Int32, 0x7F800000)) % UInt32
    zero_mask = (reinterpret(Int32, nonsign - 0x1) >> Int32(31)) % UInt32
    result = sign | (
        ((((nonsign << renorm_shift) >> 0x4) + ((0x78 - renorm_shift) << UInt32(23))) | inf_nan_mask) & ~zero_mask)
    return bitcast(Float32, result)
end

# https://github.com/pytorch/pytorch/blob/e9907a344605f44bfe8d1b760f8f5859c1bc4b44/c10/util/Float8_e4m3fn-inl.h
Base.isnan(fp8::Float8_E4M3FN) = (bitcast(UInt8, fp8) & 0x7f) == 0x7f
Base.isinf(fp8::Float8_E4M3FN) = false
Base.isfinite(fp8::Float8_E4M3FN) = !isnan(fp8)
Base.floatmin(::Type{Float8_E4M3FN}) = bitcast(Float8_E4M3FN, 0x08)
Base.floatmax(::Type{Float8_E4M3FN}) = bitcast(Float8_E4M3FN, 0x7e)
Base.typemin(::Type{Float8_E4M3FN}) = bitcast(Float8_E4M3FN, 0xfe)
Base.typemax(::Type{Float8_E4M3FN}) = floatmax(Float8_E4M3FN)
Base.eps(::Type{Float8_E4M3FN}) = bitcast(Float8_E4M3FN, 0x20)

Base.exponent_bias(::Type{Float8_E4M3FN}) = 7
Base.one(::Type{Float8_E4M3FN}) = bitcast(Float8_E4M3FN, 0x38)
Base.isone(fp8::Float8_E4M3FN) = bitcast(UInt8, fp8) == 0x38
Base.iszero(fp8::Float8_E4M3FN) = iszero(bitcast(UInt8, fp8) & 0x7f)
