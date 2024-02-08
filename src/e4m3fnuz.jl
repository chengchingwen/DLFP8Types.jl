# https://github.com/pytorch/pytorch/blob/e9907a344605f44bfe8d1b760f8f5859c1bc4b44/c10/util/Float8_e4m3fnuz.h
function Float8_E4M3FNUZ(float::Float32)
    fnuz_max = UInt32(0x87) << UInt32(23)
    denorm_mask = UInt32(0x8c) << UInt32(23)
    f_bits = reinterpret(UInt32, float)
    sign = f_bits & Base.sign_mask(Float32)
    f_bits ⊻= sign
    result = zero(UInt8)
    f_bits >= fnuz_max && return bitcast(Float8_E4M3FNUZ, 0x80)
    if f_bits < (UInt32(0x78) << UInt32(23))
        f_bits = reinterpret(UInt32, reinterpret(Float32, f_bits) + reinterpret(Float32, denorm_mask))
        result = (f_bits - denorm_mask) % UInt8
        iszero(result) && return zero(Float8_E4M3FNUZ)
    else
        mant_odd = (f_bits >> UInt32(20)) & 0x1
        f_bits += 0xc487ffff # reinterpret(UInt32, Int32(8 - 127)) << 23 + 0x7ffff
        f_bits += mant_odd
        result = (f_bits >> UInt32(20)) % UInt8
    end
    result |= (sign >> UInt32(24)) % UInt8
    return bitcast(Float8_E4M3FNUZ, result)
end

# https://github.com/pytorch/pytorch/blob/e9907a344605f44bfe8d1b760f8f5859c1bc4b44/c10/util/Float8_e4m3fnuz-inl.h
Base.isnan(fp8::Float8_E4M3FNUZ) = bitcast(UInt8, fp8) == 0x80
Base.isinf(fp8::Float8_E4M3FNUZ) = false
Base.isfinite(fp8::Float8_E4M3FNUZ) = !isnan(fp8)
Base.floatmin(::Type{Float8_E4M3FNUZ}) = bitcast(Float8_E4M3FNUZ, 0x08)
Base.floatmax(::Type{Float8_E4M3FNUZ}) = bitcast(Float8_E4M3FNUZ, 0x7f)
Base.typemin(::Type{Float8_E4M3FNUZ}) = bitcast(Float8_E4M3FNUZ, 0xff)
Base.typemax(::Type{Float8_E4M3FNUZ}) = floatmax(Float8_E4M3FNUZ)
Base.eps(::Type{Float8_E4M3FNUZ}) = bitcast(Float8_E4M3FNUZ, 0x28)

Base.exponent_bias(::Type{Float8_E4M3FNUZ}) = 8
Base.one(::Type{Float8_E4M3FNUZ}) = bitcast(Float8_E4M3FNUZ, 0x40)
Base.isone(fp8::Float8_E4M3FNUZ) = bitcast(UInt8, fp8) == 0x40
Base.iszero(fp8::Float8_E4M3FNUZ) = iszero(bitcast(UInt8, fp8))
