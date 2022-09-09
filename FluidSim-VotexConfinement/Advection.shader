Shader "VortexStreet/AdvectionVelocity_K"
{
    Properties
    {
		VelocityTex("VelocityTex", 2D) = "white" {}
    	QuantityTex("Quantity", 2D) = "white" {}
		BlockTex("BlockTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

			sampler2D VelocityTex;
			sampler2D BlockTex;
			float4 VelocityTex_TexelSize;
            sampler2D QuantityTex;
            
			float dt;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
			float4 frag(v2f i) :SV_Target{
				float4 col = float4(1,1,1,1);
				// backtrace
				float2 last_pos = i.uv - dt*tex2D(VelocityTex, i.uv);
				// semi-Lagrangian: bi-linear interpolation
				col.xy = tex2D(QuantityTex, last_pos).xy;	// advection: q = q

				// fluid-solid coupling
				if(tex2D(BlockTex, i.uv).x > 0.99f)col.xy = float2(0.0f, 0.0f);
				
				if (i.uv.x < 0.01f)col.xy = float2(1.0f, 0.0f);
				if (i.uv.x > 0.99f)col.xy = float2(-0.8f, 0.3);
				return col;
			}
            ENDCG
        }
    }
}
