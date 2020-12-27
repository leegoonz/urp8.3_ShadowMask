#ifndef UNIVERSAL_LIT_INPUT_INCLUDED
#define UNIVERSAL_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _OcclusionMap_ST;
half4 _BaseColor;
half4 _SpecColor;
half4 _EmissionColor;
half _Cutoff;
half _Smoothness;
half _Metallic;
half _BumpScale;
half _OcclusionStrength;
half _EmissionScale;
#ifdef _DUALLOBE
uniform half _LobeWeight;
#endif
CBUFFER_END

TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_SkinMap);            SAMPLER(sampler_SkinMap);
TEXTURE2D(_DualLobeSmoothnessMap);   SAMPLER(sampler_DualLobeSmoothnessMap);
TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);

#ifdef _SPECULAR_SETUP
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
#else
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
#endif
#define SAMPLE_METALLICSMOOTHNESS(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;

#ifdef _METALLICSPECGLOSSMAP
    specGloss = SAMPLE_METALLICSPECULAR(uv);
    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        specGloss.a = albedoAlpha * _Smoothness;
    #else
        specGloss.a *= _Smoothness;
    #endif
#else // _METALLICSPECGLOSSMAP
    #if _SPECULAR_SETUP
        specGloss.rgb = _SpecColor.rgb;
    #else
        specGloss.rgb = _Metallic.rrr;
    #endif

    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        specGloss.a = albedoAlpha * _Smoothness;
    #else
        specGloss.a = _Smoothness;
    #endif
#endif

    return specGloss;
}

half4 SampleMetallicRoughness(float2 uv)
{
    half4 specGloss;
    specGloss = SAMPLE_METALLICSMOOTHNESS(uv);
    specGloss.a *= _Smoothness;
    //specGloss.rgb += _Metallic.rrr;
    return specGloss;
}



half SampleOcclusion(float2 uv)
{
#ifdef _OCCLUSIONMAP
// TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
#if defined(SHADER_API_GLES)
    return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
#else
    half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
    return LerpWhiteTo(occ, _OcclusionStrength);
#endif
#else
    return 1.0;
#endif
}

inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

#if _SPECULAR_SETUP
    outSurfaceData.metallic = 1.0h;
    outSurfaceData.specular = specGloss.rgb;
#else
    outSurfaceData.metallic = specGloss.r;
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
#endif

    outSurfaceData.smoothness = specGloss.a;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = SampleOcclusion(uv);
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
}

inline void InitializeStandardLitUV2SceneSurfaceData(float2 uv , float2 uv1, out SurfaceData outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
    half4 specGloss = SampleMetallicRoughness(uv);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    outSurfaceData.metallic = specGloss.r;
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
    outSurfaceData.smoothness = specGloss.a;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    #ifdef _OCCLUSIONMAPUV1_ON
    outSurfaceData.occlusion = SampleOcclusion(uv1);
    #else
    outSurfaceData.occlusion = SampleOcclusion(uv);
    #endif
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
}


uniform half3 _SkinColor;
uniform half _ScatterScale;
inline void InitializeStandardLitUV2SurfaceData(float2 uv , float2 uv1, out SurfaceSkinData outSurfaceSkinData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceSkinData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
    half4 specGloss = SampleMetallicRoughness(uv);
    outSurfaceSkinData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    outSurfaceSkinData.metallic = specGloss.r;
    outSurfaceSkinData.specular = half3(0.0h, 0.0h, 0.0h);
    outSurfaceSkinData.smoothness = specGloss.a;
    outSurfaceSkinData.dualSmoothness = 0;
    outSurfaceSkinData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceSkinData.normalBlurTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpBlurMap , sampler_BumpBlurMap), _BumpScale);
    outSurfaceSkinData.skinScatter = SampleSkinScatter(uv, _SkinColor.rgb * _ScatterScale ,TEXTURE2D_ARGS(_SkinMap, sampler_SkinMap) );
    #ifdef _OCCLUSIONMAPUV1_ON
    outSurfaceSkinData.occlusion = SampleOcclusion(uv1);
    #else
    outSurfaceSkinData.occlusion = SampleOcclusion(uv);
    #endif
    outSurfaceSkinData.emission = SampleSkinEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap)) * _EmissionScale;
}


#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
