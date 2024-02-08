# https://github.com/pytorch/pytorch/blob/e9907a344605f44bfe8d1b760f8f5859c1bc4b44/c10/util/Float8_e5m2.h
function Float8_E5M2(float::Float32)
    fp32_inf = UInt32(255) << UInt32(23)
    fp8_max = UInt32(143) << UInt32(23)
    denorm_mask = UInt32(134) << UInt32(23)
    f_bits = reinterpret(UInt32, float)
    sign = f_bits & Base.sign_mask(Float32)
    f_bits ⊻= sign
    result = zero(UInt8)
    if f_bits >= fp8_max
        result = f_bits > fp32_inf ? 0x7f : 0x7c
    else
        if f_bits < (UInt32(113) << UInt32(23))
            f_bits = reinterpret(UInt32, reinterpret(Float32, f_bits) + reinterpret(Float32, denorm_mask))
            result = (f_bits - denorm_mask) % UInt8
        else
            mant_odd = (f_bits >> UInt32(21)) & 0x1
            f_bits += 0xc80fffff # reinterpret(UInt32, Int32(15 - 127)) << 23 + 0xfffff
            f_bits += mant_odd
            result = (f_bits >> UInt32(21)) % UInt8
        end
    end
    result |= (sign >> UInt32(24)) % UInt8
    return bitcast(Float8_E5M2, result)
end

Base.Float32(fp8::Float8_E5M2) = Float32(reinterpret(Float16, UInt16(bitcast(UInt8, fp8)) << 0x8))

# https://github.com/pytorch/pytorch/blob/e9907a344605f44bfe8d1b760f8f5859c1bc4b44/c10/util/Float8_e5m2fnuz-inl.h
Base.isnan(fp8::Float8_E5M2) = (bitcast(UInt8, fp8) & 0x7f) > 0x7c
Base.isinf(fp8::Float8_E5M2) = (bitcast(UInt8, fp8) & 0x7f) == 0x7c
Base.isfinite(fp8::Float8_E5M2) = !isnan(fp8) & !isinf(fp8)
Base.floatmin(::Type{Float8_E5M2}) = bitcast(Float8_E5M2, 0x04)
Base.floatmax(::Type{Float8_E5M2}) = bitcast(Float8_E5M2, 0x7b)
Base.typemin(::Type{Float8_E5M2}) = bitcast(Float8_E5M2, 0xfc)
Base.typemax(::Type{Float8_E5M2}) = bitcast(Float8_E5M2, 0x7c)
Base.eps(::Type{Float8_E5M2}) = bitcast(Float8_E5M2, 0x34)

Base.exponent_bias(::Type{Float8_E5M2}) = 15
Base.one(::Type{Float8_E5M2}) = bitcast(Float8_E5M2, 0x3c)
Base.isone(fp8::Float8_E5M2) = bitcast(UInt8, fp8) == 0x3c
Base.iszero(fp8::Float8_E5M2) = iszero(bitcast(UInt8, fp8) & 0x7f)
