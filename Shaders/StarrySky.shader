// Copyright(c) 2017 Funly LLC
//
// Author: Jason Ederle
// Description: Generates a customizable dynamic starry sky.
// Contact: jason@funly.io

Shader "Funly/Sky/StarrySky" {
  Properties {
    // Gradient Sky.
    _GradientSkyColor("Sky Color", Color) = (.47, .45, .75, 1)            // Color of sky.
    _GradientHorizonColor("Horizon Color", Color) = (.7, .53, .69, 1)     // Color of horizon.
    _GradientFadeBegin("Horizon Fade Begin", Range(-1, 1)) = -.179        // Position to begin horizon fade into sky.
    _GradientFadeEnd("Horizon Fade End", Range(-1, 1)) = .302             // Position to end horizon fade into sky.

    // Cubemap background.
    [NoScaleOffset]_MainTex("Background Cubemap", CUBE) = "white" {}      // Cubemap for custom background behind stars.

    // Star fading.
    _StarFadeBegin("Star Fade Begin", Range(-1, 1)) = .067                // Height to begin star fade in.
    _StarFadeEnd("Star Fade End", Range(-1, 1)) = .36                     // Height where all stars are faded in at.

    // Star Layer 1.
    [NoScaleOffset]_StarLayer1Tex("Star 1 Texture", 2D) = "white" {}
    _StarLayer1Color("Star Layer 1 - Color", Color) = (1, 1, 1, 1)                              // Color tint for stars.
    _StarLayer1Density("Star Layer 1 - Star Density", Range(0, .05)) = .01                      // Space between stars.
    _StarLayer1MaxRadius("Star Layer 1 - Star Size", Range(0, .1)) = .007                       // Max radius of stars.
    _StarLayer1TwinkleAmount("Star Layer 1 - Twinkle Amount", Range(0, 1)) = .775               // Percent of star twinkle amount.
    _StarLayer1TwinkleSpeed("Star Layer 1 - Twinkle Speed", float) = 2.0                        // Twinkle speed.
    _StarLayer1RotationSpeed("Star Layer 1 - Rotation Speed", float) = 2                        // Rotation speed of stars.
    _StarLayer1EdgeFade("Star Layer 1 - Edge Feathering", Range(0.0001, .9999)) = .2            // Softness of star blending with background.
    _StarLayer1HDRBoost("Star Layer 1 - HDR Bloom Boost", Range(1, 10)) = 1.0                   // Boost star colors so they glow with bloom filters.
    [HideInInspector]_StarLayer1DataTex("Star Layer 1 - Data Image", 2D) = "black" {}           // Data image with star positions.

    // Star Layer 2. - See property descriptions from star layer 1.
    [NoScaleOffset]_StarLayer2Tex("Star 2 Texture", 2D) = "white" {}
    _StarLayer2Color("Star Layer 2 - Color", Color) = (1, .5, .96, 1)
    _StarLayer2Density("Star Layer 2 - Star Density", Range(0, .05)) = .01
    _StarLayer2MaxRadius("Star Layer 2 - Star Size", Range(0, .4)) = .014
    _StarLayer2TwinkleAmount("Star Layer 2 - Twinkle Amount", Range(0, 1)) = .875
    _StarLayer2TwinkleSpeed("Star Layer 2 - Twinkle Speed", float) = 3.0
    _StarLayer2RotationSpeed("Star Layer 2 - Rotation Speed", float) = 2
    _StarLayer2EdgeFade("Star Layer 2 - Edge Feathering", Range(0.0001, .9999)) = .2
    _StarLayer2HDRBoost("Star Layer 2 - HDR Bloom Boost", Range(1, 10)) = 1.0
    [HideInInspector]_StarLayer2DataTex("Star Layer 2 - Data Image", 2D) = "black" {}

    // Star Layer 3. - See property descriptions from star layer 1.
    [NoScaleOffset]_StarLayer3Tex("Star 3 Texture", 2D) = "white" {}
    _StarLayer3Color("Star Layer 3 - Color", Color) = (.22, 1, .55, 1)
    _StarLayer3Density("Star Layer 3 - Star Density", Range(0, .05)) = .01
    _StarLayer3MaxRadius("Star Layer 3 - Star Size", Range(0, .4)) = .01
    _StarLayer3TwinkleAmount("Star Layer 3 - Twinkle Amount", Range(0, 1)) = .7
    _StarLayer3TwinkleSpeed("Star Layer 3 - Twinkle Speed", float) = 1.0
    _StarLayer3RotationSpeed("Star Layer 3 - Rotation Speed", float) = 2
    _StarLayer3EdgeFade("Star Layer 3 - Edge Feathering", Range(0.0001, .9999)) = .2
    _StarLayer3HDRBoost("Star Layer 3 - HDR Bloom Boost", Range(1, 10)) = 1.0
    [HideInInspector]_StarLayer3DataTex("Star Layer 1 - Data Image", 2D) = "black" {}

    // Shrink stars closer to horizon.
    _HorizonScaleFactor("Star Horizon Scale Factor", Range(0, 1)) = .7

    // Moon properties.
    [NoScaleOffset]_MoonTex("Moon Texture", 2D) = "white" {}               // Moon image.
    _MoonColor("Moon Color", Color) = (.66, .65, .55, 1)                   // Moon tint color.
    _MoonHeight("Moon Vertical Position", Range(0, 1)) = .89               // Height percent on mesh.
    _MoonAngle("Moon Horizontal Position", Range(0, 1)) =  1.57            // Rotation percent around mesh.
    _MoonRadius("Moon Size", Range(0, 1)) = .1                             // Radius of the moon.
    _MoonEdgeFade("Moon Edge Feathering", Range(0.0001, .9999)) = .3       // Soften edges of moon texture.
    _MoonHDRBoost("Moon HDR Bloom Boost", Range(1, 10)) = 1                // Control brightness for HDR bloom filter.
    [HideInInspector]_MoonComputedPositionData("Moon Position Data" , Vector) = (0, 0, 0, 0)  // Precomputed position data.
    [HideInInspector]_MoonComputedRotationData("Moon Rotation Data", Vector) = (0, 0, 0, 0)   // Precomputed rotation data.
  }

  SubShader {
    Tags { "RenderType"="Opaque" "Queue"="Background" "IgnoreProjector"="true" }
    LOD 100

    Pass {
      CGPROGRAM
      #pragma shader_feature GRADIENT_BACKGROUND
      #pragma shader_feature STAR_LAYER_1
      #pragma shader_feature STAR_LAYER_2
      #pragma shader_feature STAR_LAYER_3
      #pragma shader_feature MOON

      #pragma vertex vert
      #pragma fragment frag

      #include "UnityCG.cginc"

      struct appdata {
        float4 vertex : POSITION;
        float3 normal : NORMAL;
      };

      struct v2f {
        float verticalPosition : TEXCOORD3;
        float4 vertex : SV_POSITION;
        float3 smoothVertex : TEXCOORD5;
      };

      // Cubemap.
      samplerCUBE _MainTex;
      float4 _MainTex_ST;

      // Gradient sky.
      float _UseGradientSky;
      float4 _GradientSkyColor;
      float4 _GradientHorizonColor;

      float _GradientFadeBegin;
      float _GradientFadeEnd;

      float _StarFadeBegin;
      float _StarFadeEnd;

      // Star Layer 1
      sampler2D _StarLayer1Tex;
      float4 _StarLayer1Tex_ST;
      float4 _StarLayer1Color;
      float _StarLayer1MaxRadius;
      float _StarLayer1Density;
      float _StarLayer1TwinkleAmount;
      float _StarLayer1TwinkleSpeed;
      float _StarLayer1RotationSpeed;
      float _StarLayer1EdgeFade;
      sampler2D _StarLayer1DataTex;
      float4 _StarLayer1DataTex_ST;;
      float _StarLayer1HDRBoost;

      // Star Layer 2
      sampler2D _StarLayer2Tex;
      float4 _StarLayer2Tex_ST;
      float4 _StarLayer2Color;
      float _StarLayer2MaxRadius;
      float _StarLayer2Density;
      float _StarLayer2TwinkleAmount;
      float _StarLayer2TwinkleSpeed;
      float _StarLayer2RotationSpeed;
      float _StarLayer2EdgeFade;
      sampler2D _StarLayer2DataTex;
      float4 _StarLayer2DataTex_ST;;
      float _StarLayer2HDRBoost;

      // Star Layer 3
      sampler2D _StarLayer3Tex;
      float4 _StarLayer3Tex_ST;
      float4 _StarLayer3Color;
      float _StarLayer3MaxRadius;
      float _StarLayer3Density;
      float _StarLayer3TwinkleAmount;
      float _StarLayer3TwinkleSpeed;
      float _StarLayer3RotationSpeed;
      float _StarLayer3EdgeFade;
      sampler2D _StarLayer3DataTex;
      float4 _StarLayer3DataTex_ST;;
      float _StarLayer3HDRBoost;

      float _HorizonScaleFactor;

      // Moon
      sampler2D _MoonTex;
      float4 _MoonTex_ST;
      float4 _MoonColor;
      float _MoonRadius;
      float _MoonEdgeFade;
      float _MoonHDRBoost;
      float4 _MoonComputedPositionData;
      float4 _MoonComputedRotationData;

      #define _PI 3.14159265358
      #define _PI_2 (_PI / 2)
      #define _2_PI (_PI * 2)

      // Returns color for this fragment using both the background and star color.
      half4 MergeStarIntoBackground(float4 background, half4 starColor) {
        half starFadeAmount = starColor.a;

        background.a = 1;
        starColor.a = 1;

        // Additive overlap with star scaled using alpha.
        return background + (starColor * starFadeAmount);
      }
      
      inline float2 Rotate2d(float2 p, float angle) {
        return mul(float2x2(cos(angle), -sin(angle),
                            sin(angle), cos(angle)),
                   p);
      }

      float Atan2Positive(float y, float x) {
        float angle = atan2(y, x);
        
        // This is the same as: angle = (angle > 0) ? angle : _PI + (_PI + angle)
        float isPositive = step(0, angle);
        float posAngle = angle * isPositive;
        float negAngle = (_PI + (_PI + angle)) * !isPositive;

        return posAngle + negAngle;
      }

      float3 RotateAroundXAxis(float3 p, float angle) {
        float2 rotation = Rotate2d(p.zy, angle);
        return float3(p.x, rotation.y, rotation.x);
      }

      float3 RotateAroundYAxis(float3 p, float angle) {
        float2 rotation = Rotate2d(p.xz, angle);
        return float3(rotation.x, p.y, rotation.y);
      }

      float3 RotatePoint(float3 p, float xAxisRotation, float yAxisRotation) {
        float3 rotated = RotateAroundYAxis(p, yAxisRotation);
        return RotateAroundXAxis(rotated, xAxisRotation);
      }

      float2 GetUVsForSpherePoint(float3 fragPos, float radius, float2 pointRotation) {
        float3 projectedPosition = RotatePoint(fragPos, pointRotation.x, pointRotation.y);

        // Find our UV position.
        return clamp(float2(
          (projectedPosition.x + radius) / (2.0 * radius),
          (projectedPosition.y + radius) / (2.0 * radius)), 0, 1);
      }

      float2 Calculate2DCords(float3 spherePoint) {
        float yPercent = spherePoint.y / 2.0 + .5;
        float anglePercent = Atan2Positive(spherePoint.z, spherePoint.x) / _2_PI;
        return float2(anglePercent, yPercent);
      }

      inline float4 GetStarMetadata(float2 cords, sampler2D starData) {
        return tex2D(starData, float2(.5 + .5 * cords.x, .5 + .5 * cords.y));
      }

      inline float4 NearbyStarPoint(sampler2D nearbyStarTexture, float2 cords) {
        return tex2D(nearbyStarTexture, float2(.5 * cords.x, .5 + .5 * cords.y));
      }

      // Rotate the UVs With an animation speed.
      float2 AnimateStarRotation(float2 starUV, float rotationSpeed, float scale) {
        return Rotate2d(starUV - .5, rotationSpeed * _Time.y * scale) + .5;
      }

      half4 StarColorFromGrid(
          float3 pos,
          float2 starCoords,
          sampler2D starTexture,
          float4 starColorTint,
          float starDensity,
          float maxRadius,
          float twinkleAmount,
          float twinkleSpeed,
          float rotationSpeed,
          float edgeFade,
          sampler2D nearbyStarsTexture,
          float4 gridPointWithNoise) {
        float4 starInfo = GetStarMetadata(starCoords, nearbyStarsTexture);
        float3 gridPoint = normalize(gridPointWithNoise.xyz);

        float distanceToCenter = distance(pos, gridPoint);

        float noisePercent = gridPointWithNoise.w;
        float minRadius = clamp((1 - twinkleAmount) * maxRadius, 0, maxRadius);
        float radius = clamp(maxRadius * noisePercent, minRadius, maxRadius);

        // Even though we used a conditional, this gives a larger performance boost by bailing early.
        if (distanceToCenter > radius) {
          return half4(0, 0, 0, 0);
        }

        // Apply a horizon scale so stars are less visible with distance.
        radius *= _HorizonScaleFactor;

        // Find the UVs for the star and rotate them with some randomness.
        float2 starUV = GetUVsForSpherePoint(pos, radius, starInfo.xy);
        float2 rotatedStarUV = AnimateStarRotation(starUV, rotationSpeed * noisePercent, 1);
        half4 outputColor = tex2D(starTexture, rotatedStarUV) * starColorTint;

        // Animate alpha with twinkle wave.
        half twinkleWavePercent = smoothstep(-1, 1, cos(noisePercent * (100 + _Time.y) * twinkleSpeed));
        outputColor.a = clamp(twinkleWavePercent, (1 - twinkleAmount), 1);

        // If it's outside the radius, zero is multiplied to clear the color values.
        return outputColor * smoothstep(radius, radius * (1 - edgeFade), distanceToCenter);
      }

      struct StarData {
        sampler2D starTexture;
        float4 color;
        float density;
        float maxRadius;
        float twinkleAmount;
        float twinkleSpeed;
        float rotationSpeed;
      };
      half4 StarColorFromAllGrids(float3 pos) {
        float2 starCoords = Calculate2DCords(pos);
        float4 nearbyStar;

#ifdef STAR_LAYER_3
        nearbyStar = NearbyStarPoint(_StarLayer3DataTex, starCoords);
        if (distance(pos, nearbyStar) <= _StarLayer3MaxRadius) {
          return StarColorFromGrid(
            pos,
            starCoords,
            _StarLayer3Tex,
            _StarLayer3Color,
            _StarLayer3Density,
            _StarLayer3MaxRadius,
            _StarLayer3TwinkleAmount,
            _StarLayer3TwinkleSpeed,
            _StarLayer3RotationSpeed,
            _StarLayer3EdgeFade,
            _StarLayer3DataTex,
            nearbyStar) * _StarLayer3HDRBoost;
        }
#endif

#ifdef STAR_LAYER_2
        nearbyStar = NearbyStarPoint(_StarLayer2DataTex, starCoords);
        if (distance(pos, nearbyStar) <= _StarLayer2MaxRadius) {
          return StarColorFromGrid(
            pos,
            starCoords,
            _StarLayer2Tex,
            _StarLayer2Color,
            _StarLayer2Density,
            _StarLayer2MaxRadius,
            _StarLayer2TwinkleAmount,
            _StarLayer2TwinkleSpeed,
            _StarLayer2RotationSpeed,
            _StarLayer2EdgeFade,
            _StarLayer2DataTex,
            nearbyStar) * _StarLayer2HDRBoost;
        }
        
#endif

#ifdef STAR_LAYER_1
        nearbyStar = NearbyStarPoint(_StarLayer1DataTex, starCoords);
        if (distance(pos, nearbyStar) <= _StarLayer1MaxRadius) {
          return StarColorFromGrid(
            pos,
            starCoords,
            _StarLayer1Tex,
            _StarLayer1Color,
            _StarLayer1Density,
            _StarLayer1MaxRadius,
            _StarLayer1TwinkleAmount,
            _StarLayer1TwinkleSpeed,
            _StarLayer1RotationSpeed,
            _StarLayer1EdgeFade,
            _StarLayer1DataTex,
            nearbyStar) * _StarLayer1HDRBoost;
        }
#endif

        return half4(0, 0, 0, 0);
      }

      inline half4 FadeStarsColor(float verticalPosition, half4 currentStar) {
        return currentStar * smoothstep(_StarFadeBegin, _StarFadeEnd, verticalPosition);
      }

      half4 HorizonGradient(float verticalPosition) {
        half fadePercent = smoothstep(_GradientFadeBegin, _GradientFadeEnd, verticalPosition);
        return lerp(_GradientHorizonColor, _GradientSkyColor, fadePercent);
      }

      v2f vert(appdata v) {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.verticalPosition = clamp(v.vertex.y, -1, 1);
        o.smoothVertex = v.vertex;

        return o;
      }
      
#ifdef MOON
      half4 MoonColor(float3 pos, float3 moonPosition, float2 moonRotation) {
        float2 moonUVs = GetUVsForSpherePoint(pos, _MoonRadius, moonRotation);
        half4 color = tex2D(_MoonTex, moonUVs) * _MoonColor * _MoonHDRBoost;
        
        float fragDistance = distance(moonPosition, pos);

        float fadeEnd = _MoonRadius * (1 - _MoonEdgeFade);

        return smoothstep(_MoonRadius, fadeEnd, fragDistance) * color;
      }
#endif

      half4 frag(v2f i) : SV_Target {
#ifdef GRADIENT_BACKGROUND
        half fadePercent = smoothstep(_GradientFadeBegin, _GradientFadeEnd, i.verticalPosition);
        half4 background = lerp(_GradientHorizonColor, _GradientSkyColor, fadePercent);
#else
        half4 background = texCUBE(_MainTex, i.smoothVertex);
#endif
        
#ifdef MOON
        // If the moon is at this fragment, only render it so we overlap everthing else.
        if (distance(i.smoothVertex, _MoonComputedPositionData.xyz) <= _MoonRadius) {
          return background + MoonColor(normalize(i.smoothVertex),
            _MoonComputedPositionData.xyz,
            _MoonComputedRotationData.xy);
        }
#endif
        // Star color at current position.
        half4 starColor = StarColorFromAllGrids(normalize(i.smoothVertex));

        // Fade stars over the horizon.
        starColor = FadeStarsColor(i.verticalPosition, starColor);

        // Merge the stars over the background color.
        return MergeStarIntoBackground(background, starColor);
      }
      ENDCG
    }
  }
  CustomEditor "StarrySkyShaderEditor"
}
