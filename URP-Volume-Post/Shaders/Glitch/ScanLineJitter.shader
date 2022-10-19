Shader "CustomPost/Glitch/ScanLineJitter"
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

            float _Amount;
            float _Frequency;
            float _Threshold;

            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            float randomNoise(float x)
            {
                return frac(sin(dot(x, float2(12.9898, 78.233))) * 43758.5453);
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

                half strength = 0.5 + 0.5 * cos(_Time.y * _Frequency);
		        
		        float jitter = randomNoise(i.uv.x + _Time.y) * 2 - 1;
		        jitter *= step(_Threshold, abs(jitter)) * _Amount * strength;
		        
		        float4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, frac(i.uv + float2(0, jitter)));

                fragColor.xyz = sceneColor;
                
                fragColor = saturate(fragColor);
                return fragColor;
            }

            
            ENDHLSL
        }
    }
}
