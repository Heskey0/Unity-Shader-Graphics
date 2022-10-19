Shader "CustomPost/Glitch/WaveJitter"
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

            float _Frequency;
            float _Speed;
            float _Amount;
            float _RGBSplit;
            
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            float snoise(float2 x)
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


                half strength = 0.5 + 0.5 *cos(_Time.y * _Frequency);
		        
		        // Prepare UV
		        float uv_y = i.uv.y * _ScreenParams.y;
		        float noise_wave_1 = snoise(float2(uv_y * 0.01, _Time.y * _Speed * 20)) * (strength * _Amount * 32.0);
		        float noise_wave_2 = snoise(float2(uv_y * 0.02, _Time.y * _Speed * 10)) * (strength * _Amount * 4.0);
		        float noise_wave_x = noise_wave_1 * noise_wave_2 / _ScreenParams.x;
		        float uv_x = i.uv.x + noise_wave_x;
                
		        float rgbSplit_uv_x = (_RGBSplit * 50 + (20.0 * strength + 1.0)) * noise_wave_x / _ScreenParams.x;
        
		        // Sample RGB Color-
		        half4 colorG = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv_x, i.uv.y));
		        half4 colorRB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv_x + rgbSplit_uv_x, i.uv.y));

                fragColor = half4(colorRB.r, colorG.g, colorRB.b, colorRB.a + colorG.a);
                
                fragColor = saturate(fragColor);
                return fragColor;
            }

            
            ENDHLSL
        }
    }
}
