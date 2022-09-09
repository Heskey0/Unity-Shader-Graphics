Shader "Homework/01_1"
{
    Properties
    {
        _WaveFrequency("Frequency", Range(0.1, 10)) = 3.5
        _Speed("Speed", Range(0.1, 3)) = 0.5
        _TAU("Scale", Range(1,10)) = 6.28318530718
        _Inten("Brightness", Range(0.0005, 0.02)) = 0.005
        _FOO("FOO", Range(1,500)) = 250.0

    }
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline" 
            "LightMode"="UniversalForward"
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

            CBUFFER_START(UnityPerMaterial)
            float _FOO;
            float _WaveFrequency;
            float _Speed;
            float _TAU;
            float _Inten;
            CBUFFER_END
            
            
            struct Attributes
            {
                float4 positionOS : SV_POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float3 positionWS : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float4 screenPos : TEXCOORD4;
            };

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.uv = i.uv;
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.screenPos = ComputeScreenPos(o.positionCS);

                return o;
            }

            float4 frag(Varyings v) : SV_Target
            {
                float3 o = float3(1,1,1);
                float time = _Time.g * _Speed;
                float2 uv = v.screenPos.xy / v.screenPos.w;

                float2 p = uv*_TAU - _FOO;
                float2 i = p;
                
                float c = 1.0;
                float inten = _Inten;

                float MAX_ITER = 5;
                float n = 0; //0~5

                //0
                float t = time * (1.0 - _WaveFrequency/float(n+1));
                i = p + float2(cos(t-i.x)+sin(t+i.y), sin(t-i.y)+cos(t+i.x));
                c += 1.0/(inten*length(float2(p.x / sin(i.x+t), p.y / cos(i.y+t))));
                n++;

                // 1
                t = time * (1.0 - _WaveFrequency/float(n+1));
                i = p + float2(cos(t-i.x)+sin(t+i.y), sin(t-i.y)+cos(t+i.x));
                c += 1.0/length(float2(p.x / (sin(i.x+t)/inten), p.y / (cos(i.y+t)/inten)));
                n++;

                //2
                t = time * (1.0 - _WaveFrequency/float(n+1));
                i = p + float2(cos(t-i.x)+sin(t+i.y), sin(t-i.y)+cos(t+i.x));
                c += 1.0/length(float2(p.x / (sin(i.x+t)/inten), p.y / (cos(i.y+t)/inten)));
                n++;

                //3
                t = time * (1.0 - _WaveFrequency/float(n+1));
                i = p + float2(cos(t-i.x)+sin(t+i.y), sin(t-i.y)+cos(t+i.x));
                c += 1.0/length(float2(p.x / (sin(i.x+t)/inten), p.y / (cos(i.y+t)/inten)));
                n++;

                //4
                t = time * (1.0 - _WaveFrequency/float(n+1));
                i = p + float2(cos(t-i.x)+sin(t+i.y), sin(t-i.y)+cos(t+i.x));
                c += 1.0/length(float2(p.x / (sin(i.x+t)/inten), p.y / (cos(i.y+t)/inten)));
                
                c /= float(MAX_ITER);
                c = 1.17-pow(c, 1.4);
                o = float3(pow(abs(c), 8.0)*float3(1,1,1));
                o = clamp(o + float3(0.0, 0.35, 0.5), 0.0, 1.0);
                
                return float4(o,1);
            }
            
            ENDHLSL
        }
    }
}