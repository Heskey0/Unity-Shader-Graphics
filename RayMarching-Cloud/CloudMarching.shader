Shader "Rendering/CloudMarching"
{
    Properties
    {
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

            float3x3 m = float3x3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
            float hash( float n )
            {
                return frac(sin(n)*43758.5453);
            }
            
            //梯度噪声产生的纹理具有连续性，所以经常用来模拟山脉、云朵等具有连续性的物质，该类噪声的典型代表是Perlin Noise。
            float noise( in float3 x )
            {
                float3 p = floor(x);
                float3 f = frac(x);
            
                f = f*f*(3.0-2.0*f);    //老版一维perlin noise  
                //https://blog.csdn.net/candycat1992/article/details/50346469
                //https://zhuanlan.zhihu.com/p/68507311
            
                float n = p.x + p.y*57.0 + 113.0*p.z;
            
                float res = lerp(lerp(lerp( hash(n+  0.0), hash(n+  1.0),f.x),
                                    lerp( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                                lerp(lerp( hash(n+113.0), hash(n+114.0),f.x),
                                    lerp( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
                return res;
            }
            
            //Fractal Brownian Motion
            //分型布朗运动
            float fbm( float3 p )
            {
                float f;
                f  = 0.5000f*noise( p );
                p = mul(p,m)*2.02f;
                f += 0.2500f*noise( p );
                p = mul(p,m)*2.03f;
                f += 0.12500f*noise( p );
                p = mul(p,m)*2.01f;
                f += 0.06250f*noise( p );
                return f;
            }
            /////////////////////////////////////
            
            float stepUp(float t, float len, float smo)
            {
              float tt = fmod(t += smo, len);
              float stp = floor(t / len) - 1.0;
              return smoothstep(0.0, smo, tt) + stp;
            }
            
            //polynomial smooth minimum
            //多项式平滑最小值
            //https://zhuanlan.zhihu.com/p/281600585
            // iq's smin
            float smin( float d1, float d2, float k ) {
                float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
                return lerp( d2, d1, h ) - k*h*(1.0-h); }
            
            float sdTorus( float3 p, float2 t )
            {
              float2 q = float2(length(p.xz)-t.x,p.y);
              return length(q)-t.y;
            }

            float sdSphere (float3 p, float3 c, float r)
            {
                return distance(p,c) - r;
            }

            float sdUnion (float sd1, float sd2)
            {
                return min(sd1, sd2);
            }
            
            
            float map( in float3 p )
            {
            	float3 q = p - float3(0.0,0.5,1.0)*_Time.y;
                float f = fbm(q);

                float sd_torus = sdTorus(p * 2.0, float2(6.0, 0.005));
                float sd_sphere1 = sdSphere(p * 2.0+float3(0,-5+8*sin(_Time.y*2.0),0), float3(0,0,0), 0.005);
                float sd_sphere2 = sdSphere(p * 2.0+float3(0,-8*sin(_Time.y*2.0),0), float3(0,0,0), 0.005);

                //float sd_sphere1_noise = 1. - sd_sphere1 + f * 3.5;
                float sd = sdUnion(sd_sphere1, sd_sphere2);
            
                float sd_noise = 1. - sd + f * 3.5;
            
                return min(max(0.0,sd_noise), 1.0);
                
            
            }
            
            float jitter;
            
            #define MAX_STEPS 48
            #define SHADOW_STEPS 8
            #define VOLUME_LENGTH 15.
            #define SHADOW_LENGTH 2.

            // https://shaderbits.com/blog/creating-volumetric-ray-marcher
            float4 cloudMarch(float3 p, float3 ray)
            {
            
                float stepLength = VOLUME_LENGTH / float(MAX_STEPS);
                float shadowStepLength = SHADOW_LENGTH / float(SHADOW_STEPS);
                float3 light = normalize(float3(1.0, 2.0, 1.0));
            
                float4 sum = float4(0., 0., 0., 1.);
                
                float3 pos = p + ray * jitter * stepLength;
                
                for (int i = 0; i < MAX_STEPS; i++)
                {
                    if (sum.a < 0.1) {
                    	break;
                    }
                    float d = map(pos);     //sdf
                
                    if( d > 0.001)
                    {
                        float3 lpos = pos + light * jitter * shadowStepLength;
                        float shadow = 0.;
                
                        for (int s = 0; s < SHADOW_STEPS; s++)
                        {
                            lpos += light * shadowStepLength;
                            float lsample = map(lpos);
                            shadow += lsample;
                        }
                
                        //totalDensity
                        // = sum(sampleDensity(lpos) * stepSize)
                        float density = clamp(d * VOLUME_LENGTH / float(MAX_STEPS), 0.0, 1.0);
                        //density = map()
                        density = sin(_Time.y * .3 - 1.7) * 1. + 0.9;
            
                        //transmittance
                        // = exp(density1 * lightAbsorption)
                        //  *exp(density2 * lightAbsorption)
                        //  *...0
                        float ss = exp(-shadow * SHADOW_LENGTH / float(SHADOW_STEPS) * 1.0);
            
                        sum.rgb += ss * density * float3(1.1, 0.9, .5) * sum.a;
                        //sum.rgb *= s;
                        sum.a *= 1.-density;
            
                        sum.rgb += exp(-map(pos + float3(0,0.25,0.0)) * .2) * density * float3(0.15, 0.45, 1.1) * sum.a;
                    }
                    pos += ray * stepLength;
                }
             
                //return sum * vec4(1.1, 0.9, .5, 1);
                return sum;
            }
            
            float3x3 camera(float3 ro, float3 ta, float cr )
            {
            	float3 cw = normalize(ta - ro);
            	float3 cp = float3(sin(cr), cos(cr),0.);
            	float3 cu = normalize( cross(cw,cp) );
            	float3 cv = normalize( cross(cu,cw) );
                return float3x3( cu, cv, cw );
            }

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

			float dt;
            float4 HeightTex_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
			float4 frag(v2f i) :SV_Target{
			    float2 p = 2*(i.uv-0.5f); //<-1, 1>
                //TODO:replace one line
                //jitter = hash(p.x + p.y * 57.0 + iTime);
                jitter = 0.1;
                
                float3 ro = float3(cos(_Time.y * .333) * 8.0, -5.5, sin(_Time.y * .333) * 8.0);
                float3 ta = float3(0.0, 1., 0.0);
                float3x3 c = camera(ro, ta, 0.0);
                float3 ray = mul(normalize(float3(p, 1.75)), c);
                float4 col = cloudMarch(ro, ray);
                float3 result = col.rgb + lerp(float3(0.3, 0.6, 1.0), float3(0.05, 0.35, 1.0), p.y + 0.75) * (col.a);
                
                float sundot = clamp(dot(ray,normalize(float3(1.0, 2.0, 1.0))),0.0,1.0);
                result += 0.4*float3(1.0,0.7,0.3)*pow( sundot, 4.0 );
            
                result = pow(result, float3(1,1,1)*(1.0/2.2));
                //result = col.rgb;
				return float4(result,1);
			}
            ENDCG
        }
    }
}
