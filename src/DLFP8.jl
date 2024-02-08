module DLFP8

using Core: bitcast

export Float8_E4M3FN, Float8_E4M3FNUZ, Float8_E5M2, Float8_E5M2FNUZ

abstract type FP8{E, M} <: AbstractFloat end
const FP8E4M3 = FP8{4, 3}
const FP8E5M2 = FP8{5, 2}

# `E4M3FN`: 1 bit for the sign, 4 bits for the exponents, 3 bits for the mantissa, only nan values and no infinite values (FN)
primitive type Float8_E4M3FN <: FP8E4M3 8 end
# `E4M3FNUZ`: 1 bit for the sign, 4 bits for the exponents, 3 bits for the mantissa, only nan values and no infinite values (FN), no negative zero (UZ)
primitive type Float8_E4M3FNUZ <: FP8E4M3 8 end
# `E5M2`: 1 bit for the sign, 5 bits for the exponents, 2 bits for the mantissa
primitive type Float8_E5M2 <: FP8E5M2 8 end
# `E5M2FNUZ`: 1 bit for the sign, 5 bits for the exponents, 2 bits for the mantissa, only nan values and no infinite values (FN), no negative zero (UZ)
primitive type Float8_E5M2FNUZ <: FP8E5M2 8 end

include("e4m3fn.jl")
include("e4m3fnuz.jl")
include("e5m2.jl")
include("e5m2fnuz.jl")

Base.sign_mask(::Type{T}) where T <: FP8 = 0x80
Base.significand_mask(::Type{T}) where T <: FP8E4M3 = 0x07
Base.significand_mask(::Type{T}) where T <: FP8E5M2 = 0x03
Base.exponent_mask(::Type{T}) where T <: FP8E4M3 = 0x78
Base.exponent_mask(::Type{T}) where T <: FP8E5M2 = 0x7c
Base.exponent_bits(::Type{T}) where {E, M, T <: FP8{E, M}} = E
Base.significand_bits(::Type{T}) where {E, M, T <: FP8{E, M}} = M

Base.signbit(fp8::FP8) = bitcast(Bool, bitcast(UInt8, fp8) >> 0x7)
Base.zero(::Type{T}) where T <: FP8 = bitcast(T, 0x0)
Base.abs(fp8::T) where T <: FP8 = bitcast(T, bitcast(UInt8, fp8) & ~Base.sign_mask(T))
Base.:(-)(fp8::T) where T <: FP8 = bitcast(T, bitcast(UInt8, fp8) ⊻ Base.sign_mask(T))

Base.Float64(fp8::FP8) = Float64(Float32(fp8))
Base.Float16(fp8::FP8) = Float16(Float32(fp8))
(::Type{T})(x) where T <: FP8 = T(Float32(x))
(::Type{T})(x::T) where T <: FP8 = x

function Base.decompose(x::T) where T <: FP8
    isnan(x) && return 0, 0, 0
    isinf(x) && return ifelse(x < 0, -1, 1), 0, 0
    n = reinterpret(UInt8, x)
    s = n & Base.significand_mask(T)
    wm = Base.significand_bits(T) % UInt8
    e = (n & Base.exponent_mask(T)) >> wm
    ze = iszero(e)
    s |= UInt8(!ze) << wm
    d = ifelse(signbit(x), -1, 1)
    Int(s), Int(e) - (Base.significand_bits(T) + Base.exponent_bias(T)) + ze, d
end

# https://github.com/pytorch/pytorch/blob/e9907a344605f44bfe8d1b760f8f5859c1bc4b44/c10/util/Float8_fnuz_cvt.h
function Base.Float32(fp8::T) where T <: Union{Float8_E4M3FNUZ, Float8_E5M2FNUZ}
    iszero(fp8) && return zero(Float32)
    isnan(fp8) && return NaN32
    we = Base.exponent_bits(T) % UInt32
    wm = Base.significand_bits(T) % UInt32
    weo = UInt32(8)
    wmo = UInt32(23)
    x = reinterpret(UInt8, fp8)
    mantissa = (x & Base.significand_mask(T)) % UInt32
    exponent = ((x & Base.exponent_mask(T)) >> wm) % UInt32
    if iszero(exponent)
        renorm_shift = UInt32(leading_zeros(mantissa))
        sh = 0x1 + renorm_shift - (UInt32(32) - wm)
        mantissa <<= sh
        exponent += 0x1 - sh
        mantissa &= (UInt32(1) << wm) - 0x1
    end
    exp_low_cutoff = (UInt32(1) << (weo - 0x1)) - (UInt32(1) << (we - 0x1))
    exponent += exp_low_cutoff - 0x1
    mantissa <<= wmo - wm
    sign = x >> 0x7 % UInt32
    retval = (sign << UInt32(31)) | (exponent << UInt32(23)) | mantissa
    return bitcast(Float32, retval)
end

Base.promote_rule(::Type{T}, ::Type{F}) where {T <: FP8, F <: AbstractFloat} = sizeof(F) > sizeof(T) ? F : Union{}
Base.promote_rule(::Type{T}, ::Type{I}) where {T <: FP8, I <: Integer} = T

function Base.nextfloat(fp8::T, d::Integer) where T <: FP8
    isnan(fp8) && return fp8
    fu = reinterpret(UInt8, fp8)
    fneg = signbit(fp8)
    dneg = signbit(d)
    neg_max = reinterpret(UInt8, typemin(T))
    neg_min = 0x81
    neg_len = neg_max - neg_min
    pos_min = reinterpret(UInt8, zero(T))
    pos_max = reinterpret(UInt8, typemax(T))
    pos_len = pos_max - pos_min + 0x1
    A_min = ifelse(fneg, neg_min, pos_min)
    A_max = ifelse(fneg, neg_max, pos_max)
    A_len = ifelse(fneg, neg_len, pos_len)
    B_min = ifelse(fneg, pos_min, neg_min)
    B_max = ifelse(fneg, pos_max, neg_max)
    B_len = ifelse(fneg, pos_len, neg_len)
    du = min(abs(d), A_len + B_len) % UInt8
    if fneg ⊻ dneg
        diff = fu - A_min
        if du > diff
            da = du - diff - fneg
            next = ifelse(da >= B_len, B_max, B_min + da - dneg)
        else
            next = fu - du
        end
    else
        next = ifelse(du >= A_max - fu, A_max, fu + du)
    end
    return bitcast(T, next)
end

@inline function Base.isequal(a::T, b::T) where T <: FP8
    (isnan(a) & isnan(b)) && return true
    (iszero(a) & iszero(b)) && return true
    return bitcast(UInt8, a) == bitcast(UInt8, b)
end

@inline function Base.:(==)(a::T, b::T) where T <: FP8
    (isnan(a) | isnan(b)) && return false
    iszero(a) & iszero(b) && return true
    return bitcast(UInt8, a) == bitcast(UInt8, b)
end

Base.inttype(::Type{T}) where T <: FP8 = Int8
@inline function Base.isless(a::T, b::T) where T <: FP8
    (isnan(a) | isnan(b)) && return !isnan(a)
    return Base._fpint(a) < Base._fpint(b)
end

@inline function Base.:(<)(a::T, b::T) where T <: FP8
    (isnan(a) | isnan(b)) && return false
    (iszero(a) & iszero(b)) && return false
    return Base._fpint(a) < Base._fpint(b)
end

for bop in :[
    +, -, *, /, \, ^,
].args
    @eval Base.$bop(a::T, b::T) where T <: FP8 = T($bop(Float32(a), Float32(b)))
end

for uop in :[
    sin, cos, tan, asin, acos, atan, sinh, cosh, tanh, asinh, acosh, atanh,
    exp, exp2, exp10, expm1, log, log2, log10, sqrt, cbrt, log1p,
].args
    @eval Base.$uop(a::T) where T <: FP8 = T($uop(Float32(a)))
end

Base.print(io::IO, f::FP8) = show(io, Float32(f), true, true)
function Base.show(io::IO, f::FP8)
    typed = get(io, :typeinfo, Any) != typeof(f)
    if typed
        print(io, nameof(typeof(f)))
        print(io, '(')
    end
    print(io, f)
    typed && print(io, ')')
end

end
