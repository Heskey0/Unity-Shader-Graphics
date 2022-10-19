Shader "CustomPost/Blur/GaussianBlur"
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

            float4 _BlurOffset;
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

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

                float4 uv01 = i.uv.xyxy + _BlurOffset.xyxy * float4(1, 1, -1, -1) * 1.0;
		        float4 uv23 = i.uv.xyxy + _BlurOffset.xyxy * float4(1, 1, -1, -1) * 2.0;
		        float4 uv45 = i.uv.xyxy + _BlurOffset.xyxy * float4(1, 1, -1, -1) * 6.0;

                float4 color = float4(0,0,0,0);

                // 6/256
                color += 0.40 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                // 4/256
                color += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv01.xy);
		        color += 0.15 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv01.zw);
		        color += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv23.xy);
		        color += 0.10 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv23.zw);
		        color += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv45.xy);
		        color += 0.05 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv45.zw);
                


                fragColor.xyz = color.xyz;
                
                fragColor = saturate(fragColor);
                return fragColor;
            }

            
            ENDHLSL
        }
    }
}
