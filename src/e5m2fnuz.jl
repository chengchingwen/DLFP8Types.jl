# https://github.com/pytorch/pytorch/blob/e9907a344605f44bfe8d1b760f8f5859c1bc4b44/c10/util/Float8_e5m2fnuz.h
function Float8_E5M2FNUZ(float::Float32)
    fnuz_max = UInt32(0x8f) << UInt32(23)
    denorm_mask = UInt32(0x85) << UInt32(23)
    f_bits = reinterpret(UInt32, float)
    sign = f_bits & Base.sign_mask(Float32)
    f_bits ⊻= sign
    result = zero(UInt8)
    f_bits >= fnuz_max && return bitcast(Float8_E5M2FNUZ, 0x80)
    if f_bits < (UInt32(0x70) << UInt32(23))
        f_bits = reinterpret(UInt32, reinterpret(Float32, f_bits) + reinterpret(Float32, denorm_mask))
        result = (f_bits - denorm_mask) % UInt8
        iszero(result) && return zero(Float8_E5M2FNUZ)
    else
        mant_odd = (f_bits >> UInt32(21)) & 0x1
        f_bits += 0xc88fffff # reinterpret(UInt32, Int32(16 - 127)) << 23 + 0xfffff
        f_bits += mant_odd
        result = (f_bits >> UInt32(21)) % UInt8
    end
    result |= (sign >> UInt32(24)) % UInt8
    return bitcast(Float8_E5M2FNUZ, result)
end

# https://github.com/pytorch/pytorch/blob/e9907a344605f44bfe8d1b760f8f5859c1bc4b44/c10/util/Float8_e5m2fnuz-inl.h
Base.isnan(fp8::Float8_E5M2FNUZ) = bitcast(UInt8, fp8) == 0x80
Base.isinf(fp8::Float8_E5M2FNUZ) = false
Base.isfinite(fp8::Float8_E5M2FNUZ) = !isnan(fp8)
Base.floatmin(::Type{Float8_E5M2FNUZ}) = bitcast(Float8_E5M2FNUZ, 0x04)
Base.floatmax(::Type{Float8_E5M2FNUZ}) = bitcast(Float8_E5M2FNUZ, 0x7f)
Base.typemin(::Type{Float8_E5M2FNUZ}) = bitcast(Float8_E5M2FNUZ, 0xff)
Base.typemax(::Type{Float8_E5M2FNUZ}) = floatmax(Float8_E5M2FNUZ)
Base.eps(::Type{Float8_E5M2FNUZ}) = bitcast(Float8_E5M2FNUZ, 0x34)

Base.exponent_bias(::Type{Float8_E5M2FNUZ}) = 16
Base.one(::Type{Float8_E5M2FNUZ}) = bitcast(Float8_E5M2FNUZ, 0x40)
Base.isone(fp8::Float8_E5M2FNUZ) = bitcast(UInt8, fp8) == 0x40
Base.iszero(fp8::Float8_E5M2FNUZ) = iszero(bitcast(UInt8, fp8))
