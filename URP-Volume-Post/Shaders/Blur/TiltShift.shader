Shader "CustomPost/Blur/TiltShift"
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

            float _Radius;
            int _Iteration;

            float _Offset;
            float _Area;
            float _Spread;
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float4 _MainTex_TexelSize;
            
            float TiltShiftMask(float2 uv)
			{
				float centerY = uv.y * 2.0 - 1.0 + _Offset; // [0,1] -> [-1,1]
				return pow(abs(centerY * _Area), _Spread);
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

                // :: Golden angle ::
                // float c = cos(2.39996323f); 
                // float s = sin(2.39996323f);
                float c = -0.7374;
                float s = 0.6755;
                
                half2x2 rot = half2x2(c, s, -s, c);
		        half4 accumulator = 0.0;
		        half4 divisor = 0.0;
        
		        half r = 1.0;
            	
		        // original code: half2 axis = half2(0.0, _Radius);
            	// add Tilt Shift Mask
            	half2 axis = half2(0.0, _Radius * saturate(TiltShiftMask(i.uv)));
        
		        for (int j = 0; j < _Iteration + 1; j++)
		        {
		            // (r-1.0): increase from 0 slower and slower, converge to 1
		        	r += 1.0 / r;
		            // rotate the axis
		        	axis = mul(rot, axis);  
		        	half4 bokeh = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(i.uv + _MainTex_TexelSize.xy * (r - 1.0) * axis));
		        	accumulator += bokeh * bokeh;
		        	divisor += bokeh;
		        }
		        half4 color = accumulator / divisor;

                fragColor.xyz = color.xyz;
                
                fragColor = saturate(fragColor);
                return fragColor;
            }

            
            ENDHLSL
        }
    }
}
