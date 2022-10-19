Shader "CustomPost/Blur/Kawase"
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

            float _BlurRadius;


            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float4 _MainTex_TexelSize;
            
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

                half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                float4 color = float4(0,0,0,0);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(-_BlurRadius-1.0, -_BlurRadius-1.0)*_MainTex_TexelSize.xy);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2( _BlurRadius+1.0, -_BlurRadius-1.0)*_MainTex_TexelSize.xy);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(-_BlurRadius-1.0,  _BlurRadius+1.0)*_MainTex_TexelSize.xy);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2( _BlurRadius+1.0,  _BlurRadius+1.0)*_MainTex_TexelSize.xy);
        
		        color *= 0.25f;

                fragColor.xyz = color.xyz;
                
                fragColor = saturate(fragColor);
                return fragColor;
            }

            
            ENDHLSL
        }
    }
}
