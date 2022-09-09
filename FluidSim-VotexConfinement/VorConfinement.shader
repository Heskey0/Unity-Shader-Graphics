Shader "Unlit/VorConfinement"
{
    Properties
    {
        VelocityTex ("VelocityTex", 2D) = "white" {}
        VorticityTex ("VorticityTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D VelocityTex;
            sampler2D VorticityTex;

            float4 VorticityTex_TexelSize;
            float curl_strength;
            float dt;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = float4(0,0,0,1);
                float L = tex2D(VorticityTex, i.uv - float2(VorticityTex_TexelSize.x, 0.0)).z;
                float R = tex2D(VorticityTex, i.uv + float2(VorticityTex_TexelSize.x, 0.0)).z;
                float B = tex2D(VorticityTex, i.uv - float2(0.0, VorticityTex_TexelSize.y)).z;
                float T = tex2D(VorticityTex, i.uv + float2(0.0, VorticityTex_TexelSize.y)).z;
                float C = tex2D(VorticityTex, i.uv).z;

                float2 N = float2(T-B, L-R);
                float2 force = curl_strength * C * N/(length(N)+0.01);

                float2 velocity = tex2D(VelocityTex, i.uv).xy;
                col.xy = velocity + force * dt;
                col.z = 0.0;
                return col;
            }
            ENDCG
        }
    }
}
