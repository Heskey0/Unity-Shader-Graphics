Shader "Unlit/Vorticity"
{
    Properties
    {
        VelocityTex ("Texture", 2D) = "white" {}
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

            sampler2D VelocityTex;
            float4 VelocityTex_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = float4(0,0,0,1);
                float2 L = tex2D(VelocityTex, i.uv - float2(VelocityTex_TexelSize.x, 0.0)).xy;
                float2 R = tex2D(VelocityTex, i.uv + float2(VelocityTex_TexelSize.x, 0.0)).xy;
                float2 B = tex2D(VelocityTex, i.uv - float2(0.0, VelocityTex_TexelSize.y)).xy;
                float2 T = tex2D(VelocityTex, i.uv + float2(0.0, VelocityTex_TexelSize.y)).xy;

                col.xy = float2(0, 0);
                col.z = (R.y-L.y - (T.x-B.x)) * 0.5f;   // along the z axis

                return col;
            }
            ENDCG
        }
    }
}
