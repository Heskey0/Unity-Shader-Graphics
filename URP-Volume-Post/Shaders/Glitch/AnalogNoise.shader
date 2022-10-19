Shader "CustomPost/Glitch/AnalogNoise"
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

            float _Speed;
            float _LuminanceJitterThreshold;
            float _Fading;

            
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

                half4 sceneColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
		        half4 noiseColor = sceneColor;
        
		        half luminance = dot(noiseColor.rgb, float3(0.22, 0.707, 0.071));
		        if (randomNoise(float2(_Time.x * _Speed, _Time.x * _Speed)) > _LuminanceJitterThreshold)
		        {
		        	noiseColor = float4(luminance, luminance, luminance, luminance);
		        }
        
		        float noiseX = randomNoise(_Time.x * _Speed + i.uv / float2(-213, 5.53));
		        float noiseY = randomNoise(_Time.x * _Speed - i.uv / float2(213, -5.53));
		        float noiseZ = randomNoise(_Time.x * _Speed + i.uv / float2(213, 5.53));
        
		        noiseColor.rgb += 0.25 * float3(noiseX,noiseY,noiseZ) - 0.125;
        
		        noiseColor = lerp(sceneColor, noiseColor, _Fading);

                fragColor.xyz = noiseColor;
                
                fragColor = saturate(fragColor);
                return fragColor;
            }

            
            ENDHLSL
        }
    }
}
