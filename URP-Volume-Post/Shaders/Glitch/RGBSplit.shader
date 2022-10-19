Shader "CustomPost/Glitch/RGBSplit"
{
    Properties
    {
        _MainTex("Base Map", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderingPipeline" = "UniversalForward"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float _Intensity;
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            float randomNoise(float x, float y)
            {
                return frac(sin(dot(float2(x, y), float2(12.9898, 78.233))) * 43758.5453);
            }

            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionCS : POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = v.uv;
                return o;
            }

            float4 frag(Varyings i) : SV_TARGET
            {
                float4 fragColor = float4(0,0,0,1);

                float3 color = float4(0,0,0,0);

                float splitAmount = _Intensity * randomNoise(_Time.y, 2);

                half ColorR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv.x + splitAmount, i.uv.y)).x;
                half ColorG = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).y;
                half ColorB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv.x - splitAmount, i.uv.y)).z;

                color = float3(ColorR, ColorG, ColorB);

                fragColor.xyz = color.xyz;
                
                fragColor = saturate(fragColor);
                return fragColor;
            }

            
            ENDHLSL
        }
    }
}
