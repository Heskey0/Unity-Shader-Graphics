Shader "CustomPost/Blur/TentBlur"
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

            float _Offset;
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_TexelSize;
            
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

                float2 uv = i.uv;
                float4 d = _Offset * _MainTex_TexelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0);

                float4 color = float4(0,0,0,0);

		        color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv - d.xy);
		        color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv - d.wy) * 2.0; // 1 MAD
		        color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv - d.zy); // 1 MAD
		        
		        color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + d.zw) * 2.0; // 1 MAD
		        color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv) * 4.0; // 1 MAD
		        color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + d.xw) * 2.0; // 1 MAD
		        
		        color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + d.zy);
		        color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + d.wy) * 2.0; // 1 MAD
		        color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + d.xy);

                color *= 1.0 / 16.0;

                fragColor.xyz = color.xyz;
                
                fragColor = saturate(fragColor);
                return fragColor;
            }

            
            ENDHLSL
        }
    }
}
