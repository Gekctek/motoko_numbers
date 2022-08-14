import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Int64 "mo:base/Int64";
import Float "mo:base/Float";
import Binary "./Binary";
  
  module {
    public type FloatPrecision = {#f16; #f32; #f64};

    public type FloatX = {
        isNegative: Bool;
        exponent: Nat64;
        mantissa: Nat64;
    };
    type FloatBits = {
        isNegative: Bool;
        exponentBits: Nat64;
        mantissaBits: Nat64;
    };

    public type PrecisionBitInfo = {
        exponentBitLength: Nat8;
        mantissaBitLength: Nat8;
    };

    public func getPrecisionBitInfo(precision: FloatPrecision) : PrecisionBitInfo {
        switch (precision) {
            case (#f16) {
                exponentBitLength = 5;
                mantissaBitLength = 10;
            };
            case (#f32) {
                exponentBitLength = 8;
                mantissaBitLength = 23;
            };
            case (#f64) {
                exponentBitLength = 11;
                mantissaBitLength = 52;
            };
        };
    };

    public func floatToFloatX(f: Float, precision: FloatPrecision) : FloatX {
        let bitInfo: FloatBitInfo = getBitInfo(precision);
        floatToFloatXInternal(f, bitInfo);
    };


    private func floatXToFloatInternal(isNegative: Bool, exponentBits: Nat64, mantissaBits: Nat64, bitInfo: FloatBitInfo) : Float {
        // Convert bits into numbers
        // e = 2 ^ (exponent - (2 ^ exponentBitLength / 2 - 1))
        let e: Int64 = Int64.pow(2, Int64.fromNat64(exponentBits) - ((Int64.fromNat64(Nat64.pow(2, bitInfo.exponentBitLength) / 2)) - 1));
        // moi = 2 ^ (mantissaBitLength * -1)
        let maxOffsetInverse: Float = Float.pow(2, Float.fromInt64(Int64.fromNat64(bitInfo.mantissaBitLength)) * -1);
        // m = 1 + mantissa * moi
        let m: Float = 1.0 + (Float.fromInt64(Int64.fromNat64(mantissaBits)) * maxOffsetInverse);
        // v = e * m
        var floatValue: Float = Float.fromInt64(e) * m;

        if (isNegative) {
            floatValue := Float.mul(floatValue, -1.0);
        };
        
        floatValue;
    };

    private func floatToFloatXInternal(float: Float, bitInfo: FloatBitInfo) : FloatX {
        // TODO convert 
        let isNegative = float < 0;

        // exponent is the power of 2 that is closest to the value without going over
        // exponent = trunc(log2(|value|))
        // where log2(x) = log(x)/log(2)
        let e = Float.log(Float.abs(float))/Float.log(2);
        let exponent: Nat64 = Int64.toNat64(Float.toInt64(e)); // Truncate
        // Max bit value is how many values can fit in the bit length
        let maxBitValue: Nat64 = Int64.toNat64(Float.toInt64(Float.pow(2, Float.fromInt64(Int64.fromNat64(bitInfo.exponentBitLength)))));
        // Exponent bits is a range of -(2^expBitLength/2) -1 -> (2^expBitLength/2)
        let exponentBits: Nat64 = exponent + ((maxBitValue / 2) - 1);

        // mantissaMaxOffset = 2 ^ mantissaBitLength
        let mantissaMaxOffset: Nat64 = Int64.toNat64(Float.toInt64(Float.pow(2, Float.fromInt64(Int64.fromNat64(bitInfo.mantissaBitLength)))));
        // The mantissa is the % of the exponent as the remainder between exponent and real value
        let mantissa: Float = (float / Float.pow(2, Float.fromInt64(Int64.fromNat64(exponent)))) - 1;
        // Bits represent how many offsets there are between the exponent and the value
        let mantissaBits: Nat64 = Int64.toNat64(Float.toInt64(Float.nearest(mantissa * Float.fromInt64(Int64.fromNat64(mantissaMaxOffset)))));
        {
            isNegative = isNegative;
            exponentBits = exponentBits;
            mantissaBits = mantissaBits
        };
    };
  }