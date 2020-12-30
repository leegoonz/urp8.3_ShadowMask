#ifndef FUZZ_LIGHTING_INCLUDE
#define FUZZ_LIGHTING_INCLUDE

inline half DotClamped (half3 a, half3 b)
{
    #if (SHADER_TARGET < 30)
    return saturate(dot(a, b));
    #else
    return max(0.0h, dot(a, b));
    #endif
}

float3 _FuzzColor;
sampler2D _FuzzTex;
float4 _FuzzTex_ST;
float _FuzzRange;
float _FuzzBias;
float _WrapDiffuse;

float3 WrappedDiffuse(half NdotL, half _Wrap)
{
    return saturate((NdotL + _Wrap) / ((1 + _Wrap) * (1 + _Wrap)));
}

inline half3 Fuzz(half NdotV, half3 Color, half FuzzRange, half FuzzBias)
{
    half3 FuzzColor = pow(exp2( - NdotV), FuzzRange) + FuzzBias;
    FuzzColor *= Color;
    return FuzzColor;
}


inline half3 FuzzLighting( half NdotV , half NdotL , half2 uv , half Occlusion , half3 attenColor , half3 indirectDiffuse)
{
    half2 uv_fuzz = uv.xy * _FuzzTex_ST.xy + _FuzzTex_ST.zw;
    half fuzzMap_var = tex2D(_FuzzTex, uv_fuzz.xy).x;
    half3 FuzzLightingOut = 0;
    FuzzLightingOut = Fuzz(NdotV,fuzzMap_var.xyz*Occlusion.r*(_FuzzColor * indirectDiffuse + _FuzzColor * WrappedDiffuse(NdotL, _WrapDiffuse) * attenColor.rgb), _FuzzRange, _FuzzBias);

    return FuzzLightingOut;
}

#endif