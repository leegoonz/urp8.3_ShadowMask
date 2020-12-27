#ifndef UNIVERSAL_INPUT_SURFACE_INCLUDED
#define UNIVERSAL_INPUT_SURFACE_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
TEXTURE2D(_BumpMap);            SAMPLER(sampler_BumpMap);
TEXTURE2D(_BumpBlurMap);        SAMPLER(sampler_BumpBlurMap);
TEXTURE2D(_CuvatureMap);        SAMPLER(sampler_CuvatureMap);
TEXTURE2D(_EmissionMap);        SAMPLER(sampler_EmissionMap);

// Must match Universal ShaderGraph master node
struct SurfaceData
{
    half3 albedo;
    half3 specular;
    half  metallic;
    half  smoothness;
    half3 normalTS;
    half3 emission;
    half  occlusion;
    half  alpha;
};
struct SurfaceSkinData
{
    half3 albedo;
    half3 specular;
    half  metallic;
    half  smoothness;
    half  dualSmoothness;
    half3 normalTS;
    half3 normalBlurTS;
    half3 emission;
    half4 skinScatter;
    half  occlusion;
    half  alpha;
};


///////////////////////////////////////////////////////////////////////////////
//                      Material Property Helpers                            //
///////////////////////////////////////////////////////////////////////////////
half Alpha(half albedoAlpha, half4 color, half cutoff)
{
#if !defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A) && !defined(_GLOSSINESS_FROM_BASE_ALPHA)
    half alpha = albedoAlpha * color.a;
#else
    half alpha = color.a;
#endif

#if defined(_ALPHATEST_ON)
    clip(alpha - cutoff);
#endif

    return alpha;
}

half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
{
    return SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv);
}

half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = 1.0h)
{
#ifdef _NORMALMAP
    half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
    #if BUMP_SCALE_NOT_SUPPORTED
        return UnpackNormal(n);
    #else
        return UnpackNormalScale(n, scale);
    #endif
#else
    return half3(0.0h, 0.0h, 1.0h);
#endif
}

half3 SampleEmission(float2 uv, half3 emissionColor, TEXTURE2D_PARAM(emissionMap, sampler_emissionMap))
{
#ifndef _EMISSION
    return 0;
#else
    return SAMPLE_TEXTURE2D(emissionMap, sampler_emissionMap, uv).rgb * emissionColor;
#endif
}

half3 SampleSkinEmission(float2 uv, half3 emissionColor, TEXTURE2D_PARAM(emissionMap, sampler_emissionMap))
{
    half4 emissionSampler = 0; 
    #ifndef _EMISSION
    return 0;
    #else
    emissionSampler = SAMPLE_TEXTURE2D(emissionMap, sampler_emissionMap, uv).rgba;
    emissionSampler.rgb = lerp(emissionSampler.rgb , emissionColor * emissionSampler.rgb , emissionSampler.a);
    emissionSampler.rgb = lerp(0 , emissionSampler.rgb , emissionSampler.a);
    return emissionSampler.rgb;
    #endif
}
half4 SampleSkinScatter(float2 uv, half3 scatterColor, TEXTURE2D_PARAM(scatterMap, sampler_scatterMap))
{
    half4 scatterSampler = 0; 
    #ifndef _SKINSCATTER
    return 0;
    #else
    scatterSampler = SAMPLE_TEXTURE2D(scatterMap, sampler_scatterMap, uv).rgba;
    scatterSampler.rgb = lerp(scatterSampler.rgb , scatterColor * scatterSampler.rgb , scatterSampler.a);
    scatterSampler.rgb = lerp(0 , scatterSampler.rgb , scatterSampler.a);
    return scatterSampler.rgba;
    #endif
}


#endif
