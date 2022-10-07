Shader "Custom/C_Water"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
        
        [Header(PBR Light)][Space(10)]
        _WeightPBR("Weight PBR", Range(0, 1))=1.0
        _DiffusePBR("Diffuse PBR", Range(0, 1)) = 0.276
        _roughness       ("Roughness"    , Range(0, 1)) = 0.555
        _metallic        ("Metallic"     , Range(0, 1)) = 0.495
        _subsurface      ("Subsurface"   , Range(0, 1)) = 0.467
        _anisotropic     ("Anisotropic"  , Range(0, 1)) = 0
        _specular        ("Specular"     , Range(0, 1)) = 1
        _specularTint    ("Specular Tint", Range(0, 1)) = 0.489
        _sheenTint       ("Sheen Tint"   , Range(0, 1)) = 0.5
        _sheen           ("Sheen"        , Range(0, 1)) = 0.5
        _clearcoat       ("Clearcoar"    , Range(0, 1)) = 0.5
        _clearcoatGloss  ("Clearcoat Gloss", Range(0, 1)) = 1
        _ior             ("index of refraction", Range(0, 10)) = 10
        
        [Header(NPR Light)][Space(10)]
        _WeightNPR("Weight NPR", Range(0, 1))=1.0
        _RampTex("Ramp Tex", 2D) = "white" {}
        _RampOffset("Ramp Offset", Range(-1,1)) = 0
        _StepSmoothness("Step Smoothness", Range(0.01, 0.2)) = 0.05
        _NPR_Color1("NPR Color 1", color) = (1,1,1,1)
        _NPR_Color2("NPR Color 2", color) = (1,1,1,1)
        
        [Header(Env Light)][Space(10)]
        _WeightEnvLight("Weight EnvLight", Range(0, 1)) = 0.1
        [NoScaleOffset] _Cubemap ("Envmap", cube) = "_Skybox" {}
        _CubemapMip ("Envmap Mip", Range(0, 7)) = 0
        _IBL_LUT("Precomputed integral LUT", 2D) = "white" {}
        _FresnelPow ("FresnelPow", Range(0, 5)) = 1
        _FresnelColor ("FresnelColor", Color) = (1,1,1,1)
        
        [Header(Wave Params)][Space(10)]
        _HeightXZScale("HeightField Scale", Range(1.0, 2000.0)) = 500.0
        _HeightYScale("Height Y Scale", Range(0.02, 2.0)) = 0.2
        _NormalScale("Normal Scale", Range(1.0, 2000.0)) = 1000.0
        _WaveVelocity("Wave Velocity", Range(0.1, 5.0)) = 1.0
    }
    SubShader
    {
        Tags 
        { 
            "RenderPipeline"="UniversalPipeline"
            "LightMode"="UniversalForward"
            "RenderType"="Opaque"
        }

        LOD 100
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float4 _BaseColor;

            // PBR Light
            float _WeightPBR;
            float _DiffusePBR;
            float _roughness;
            float _specular;
            float _specularTint;
            float _sheenTint;
            float _metallic;
            float _anisotropic;
            float _sheen;
            float _clearcoatGloss;
            float _subsurface;
            float _clearcoat;
            float _ior;

            // NPR
            float _WeightNPR;
            float _RampOffset;
            float _StepSmoothness;
            float4 _NPR_Color1;
            float4 _NPR_Color2;

            // EnvLight
            float _WeightEnvLight;
            samplerCUBE _Cubemap;
            float _CubemapMip;
            float _FresnelPow;
            float4 _FresnelColor;

            TEXTURE2D(_IBL_LUT);
            SAMPLER(sampler_IBL_LUT);

            // Wave Params
            float _HeightXZScale;
            float _HeightYScale;
            float _NormalScale;
            float _WaveVelocity;
            
            
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 bitangentWS : TEXCOORD4;
            };

            
            ///
            /// helper
            /// 
            float3 mon2lin(float3 x)
            {
                return float3(pow(x[0], 2.2), pow(x[1], 2.2), pow(x[2], 2.2));
            }
            float sqr(float x) { return x*x; }

            ///
            /// PBR direct
            ///
            
            float3 compute_F0(float eta)
            {
                return pow((eta-1)/(eta+1), 2);
            }
            float3 F_fresnelSchlick(float VdotH, float3 F0)  // F
            {
                return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
            }
            float3 F_SimpleSchlick(float HdotL, float3 F0)
            {
                return lerp(exp2((-5.55473*HdotL-6.98316)*HdotL), 1, F0);
            }
            
            float SchlickFresnel(float u)
            {
                float m = clamp(1-u, 0, 1);
                float m2 = m*m;
                return m2*m2*m; // pow(m,5)
            }
            float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
            {
                return F0 + (max(float3(1.0 - roughness,1.0 - roughness,1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
            }   

            float GTR1(float NdotH, float a)
            {
                if (a >= 1) return 1/PI;
                float a2 = a*a;
                float t = 1 + (a2-1)*NdotH*NdotH;
                return (a2-1) / (PI*log(a2)*t);
            }
            
            float D_GTR2(float NdotH, float a)    // D
            {
                float a2 = a*a;
                float t = 1 + (a2-1)*NdotH*NdotH;
                return a2 / (PI * t*t);
            }
            
            // X: tangent
            // Y: bitangent
            // ax: roughness along x-axis
            float GTR2_aniso(float NdotH, float HdotX, float HdotY, float ax, float ay)
            {
                return 1 / (PI * ax*ay * sqr( sqr(HdotX/ax) + sqr(HdotY/ay) + NdotH*NdotH ));
            }
            
            float smithG_GGX(float NdotV, float alphaG)
            {
                float a = alphaG*alphaG;
                float b = NdotV*NdotV;
                return 1 / (NdotV + sqrt(a + b - a*b));
            }

            float GeometrySchlickGGX(float NdotV, float k)
            {
                float nom   = NdotV;
                float denom = NdotV * (1.0 - k) + k;
            
                return nom / denom;
            }
            
            float G_Smith(float3 N, float3 V, float3 L)
            {
                float k = pow(_roughness+1, 2)/8;
                float NdotV = max(dot(N, V), 0.0);
                float NdotL = max(dot(N, L), 0.0);
                float ggx1 = GeometrySchlickGGX(NdotV, k);
                float ggx2 = GeometrySchlickGGX(NdotL, k);
            
                return ggx1 * ggx2;
            }
            
            float smithG_GGX_aniso(float NdotV, float VdotX, float VdotY, float ax, float ay)
            {
                return 1 / (NdotV + sqrt( sqr(VdotX*ax) + sqr(VdotY*ay) + sqr(NdotV) ));
            }

            float3 Diffuse_Burley_Disney( float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH )
            {
            	float FD90 = 0.5 + 2 * VoH * VoH * Roughness;
            	float FdV = 1 + (FD90 - 1) * pow(1 - NoV, 5);
            	float FdL = 1 + (FD90 - 1) * pow(1 - NoL, 5);
            	return DiffuseColor * ((1 / PI) * FdV * FdL);
            }

            float3 Diffuse_Simple(float3 DiffuseColor, float3 F, float NdotL)
            {
                float3 KD = (1-F)*(1-_metallic);
                return KD*DiffuseColor*GetMainLight().color*NdotL;
            }
            
            float SSS( float3 L, float3 V, float3 N, float3 baseColor)
            {
                float NdotL = dot(N,L);
                float NdotV = dot(N,V);
                if (NdotL < 0 || NdotV < 0)
                {
                    //NdotL = 0.15f;
                }
                float3 H = normalize(L+V);
                float LdotH = dot(L,H);

                float3 Cdlin = mon2lin(baseColor);
                if (NdotL < 0 || NdotV < 0)
                {
                    return (1/PI)*Cdlin * (1-_metallic);
                }

                float FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
                float Fd90 = 0.5 + 2 * LdotH*LdotH * _roughness;
                float Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);
                
                float Fss90 = LdotH*LdotH*_roughness;
                float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
                float ss = 1.25 * (Fss * (1 / (NdotL + NdotV) - .5) + .5);

                
                return (1/PI) * lerp(Fd, ss, _subsurface)*Cdlin * (1-_metallic);
            }

            float3 BRDF_Simple( float3 L, float3 V, float3 N, float3 X, float3 Y, float3 baseColor)
            {
                float NdotL = dot(N,L);
                float NdotV = dot(N,V);
                
                float3 H = normalize(L+V);
                float NdotH = dot(N,H);
                float LdotH = dot(L,H);
                float VdotH = dot(V,H);
                float HdotL = dot(H,L);

                float D;

                if (_anisotropic < 0.1f)
                {
                    D = D_GTR2(NdotH, _roughness);
                }
                else
                {
                    float aspect = sqrt(1-_anisotropic*.9);
                    float ax = max(.001, sqr(_roughness)/aspect);
                    float ay = max(.001, sqr(_roughness)*aspect);
                    D = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
                }
                
                //float F = F_fresnelSchlick(VdotH, compute_F0(_ior));
                float3 F = F_SimpleSchlick(HdotL, compute_F0(_ior));
                float G = G_Smith(N,V,L);

                float3 brdf = D*F*G / (4*NdotL*NdotV);

                float3 brdf_diff = Diffuse_Simple(baseColor, F, NdotL);
                
                return saturate(brdf * GetMainLight().color * NdotL * PI + brdf_diff);
            }
            
            float3 BRDF_Disney( float3 L, float3 V, float3 N, float3 X, float3 Y, float3 baseColor)
            {
                float NdotL = dot(N,L);
                float NdotV = dot(N,V);

                if (NdotL < 0 || NdotV < 0)
                {
                    NdotL=0.1f;
                }
            
                float3 H = normalize(L+V);
                float NdotH = dot(N,H);
                float LdotH = dot(L,H);
                
                
                float3 Cdlin = mon2lin(baseColor);
                float Cdlum = .3*Cdlin.x + .6*Cdlin.y  + .1*Cdlin.z; // luminance approx.
            
                float3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : float3(1,1,1); // normalize lum. to isolate hue+sat
                float3 Cspec0 = lerp(_specular*.08*lerp(float3(1,1,1), Ctint, _specularTint), Cdlin, _metallic);
                float3 Csheen = lerp(float3(1,1,1), Ctint, _sheenTint);
            
                // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
                // and mix in diffuse retro-reflection based on roughness
                float FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
                float Fd90 = 0.5 + 2 * LdotH*LdotH * _roughness;
                float Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);
            
                // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
                // 1.25 scale is used to (roughly) preserve albedo
                // Fss90 used to "flatten" retroreflection based on roughness
                float Fss90 = LdotH*LdotH*_roughness;
                float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
                float ss = 1.25 * (Fss * (1 / (NdotL + NdotV) - .5) + .5);
            
                // specular
                float aspect = sqrt(1-_anisotropic*.9);
                float ax = max(.001, sqr(_roughness)/aspect);
                float ay = max(.001, sqr(_roughness)*aspect);
                float Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
                float FH = SchlickFresnel(LdotH);
                float3 Fs = lerp(Cspec0, float3(1,1,1), FH);
                float Gs;
                Gs  = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
                Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);
            
                // sheen
                float3 Fsheen = FH * _sheen * Csheen;
            
                // clearcoat (ior = 1.5 -> F0 = 0.04)
                float Dr = GTR1(NdotH, lerp(.1,.001,_clearcoatGloss));
                float Fr = lerp(.04, 1.0, FH);
                float Gr = smithG_GGX(NdotL, .25) * smithG_GGX(NdotV, .25);
                
                return saturate(((1/PI) * lerp(Fd, ss, _subsurface)*Cdlin + Fsheen)
                    * (1-_metallic)
                    + Gs*Fs*Ds + .25*_clearcoat*Gr*Fr*Dr);
            }

            ///
            /// PBR indirect
            ///
            float3 F_Indir(float NdotV,float3 F0,float roughness)
            {
                float Fre=exp2((-5.55473*NdotV-6.98316)*NdotV);
                return F0+Fre*saturate(1-roughness-F0);
            }
            // sample spherical harmonics
            float3 Env_Diffuse(float3 N)
            {
                real4 SHCoefficients[7];
                SHCoefficients[0] = unity_SHAr;
                SHCoefficients[1] = unity_SHAg;
                SHCoefficients[2] = unity_SHAb;
                SHCoefficients[3] = unity_SHBr;
                SHCoefficients[4] = unity_SHBg;
                SHCoefficients[5] = unity_SHBb;
                SHCoefficients[6] = unity_SHC;
            
                return max(float3(0, 0, 0), SampleSH9(SHCoefficients, N));
            }

            // sample reflection probe
            float3 Env_SpecularProbe(float3 N, float3 V)
            {
                float3 reflectWS = reflect(-V, N);
                float mip = _roughness * (1.7 - 0.7 * _roughness) * 6;

                float4 specColorProbe = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectWS, mip);
                float3 decode_specColorProbe = DecodeHDREnvironment(specColorProbe, unity_SpecCube0_HDR);
                return decode_specColorProbe;
            }
            
            float3 BRDF_Indirect_Simple( float3 L, float3 V, float3 N, float3 X, float3 Y, float3 baseColor)
            {
                float3 relfectWS = reflect(-V, N);
                float3 env_Cubemap = texCUBElod(_Cubemap, float4(relfectWS, _CubemapMip)).rgb;
                float fresnel = pow(max(0.0, 1.0 - dot(N,V)), _FresnelPow);
                float3 env_Fresnel = env_Cubemap * fresnel + _FresnelColor * fresnel;

                return env_Fresnel;
            }
            float3 BRDF_Indirect( float3 L, float3 V, float3 N, float3 X, float3 Y, float3 baseColor)
            {
                // diff
                float3 F = F_Indir(dot(N,V), compute_F0(_ior), _roughness);
                float3 env_diff = Env_Diffuse(N)*(1-F)*(1-_metallic)*baseColor;

                // specular
                float3 env_specProbe = Env_SpecularProbe(N,V);
                float3 Flast = fresnelSchlickRoughness(max(dot(N,V), 0.0), compute_F0(_ior), _roughness);
                float2 envBDRF = SAMPLE_TEXTURE2D(_IBL_LUT, sampler_IBL_LUT, float2(dot(N,V), _roughness)).rg;
                float3 env_specular = env_specProbe * (Flast * envBDRF.r + envBDRF.g);

                return saturate(env_diff + env_specular);
            }
            

            ///
            /// Surface Noise
            ///
            float hash11(float n)    // in [0,1]
            {
                return frac(sin(n*13.)*43758.5453);
            }
            float hash21 (float2 _st) {
                return frac(sin(dot(_st.xy,float2(12.9898,78.233)))*43758.5453123);
            }
            float2 hash22(float2 p) {
                return frac(sin(float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3))))*43758.5453);
            }
            float hash31(float3 p)  // replace this by something better
            {
                // :: enable very high height field ::
                #if 0
                p  = 13.0*fract( p*0.3183099 + .1);
                return -1.0 + 2.0*fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
                #else
                float n = p.x + p.y*57.0 + 113.0*p.z;
                return hash11(n);
                #endif
            }
            float3 hash33(float3 p3)
            {
            	p3 = frac(p3 * float3(.1031,.11369,.13787));
                p3 += dot(p3, p3.yxz+19.19);
                return -1.0 + 2.0 * frac(float3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
            }
            float value_noise(float3 p)
            {
                float3 pi = floor(p);
                float3 pf = p - pi;
                
                float3 w = pf * pf * (3.0 - 2.0 * pf);
                
                return 	lerp(
                    		lerp(
                    			lerp(hash31(pi + float3(0, 0, 0)), hash31(pi + float3(1, 0, 0)), w.x),
                    			lerp(hash31(pi + float3(0, 0, 1)), hash31(pi + float3(1, 0, 1)), w.x), 
                                w.z),
                    		lerp(
                                lerp(hash31(pi + float3(0, 1, 0)), hash31(pi + float3(1, 1, 0)), w.x),
                    			lerp(hash31(pi + float3(0, 1, 1)), hash31(pi + float3(1, 1, 1)), w.x), 
                                w.z),
                    		w.y);
            }
            
            float perlin_noise(float3 p)
            {
                float3 pi = floor(p);
                float3 pf = p - pi;
                
                float3 w = pf * pf * (3.0 - 2.0 * pf);
                
                return 	lerp(
                    		lerp(
                            	lerp(dot(pf - float3(0, 0, 0), hash33(pi + float3(0, 0, 0))), 
                                    dot(pf - float3(1, 0, 0), hash33(pi + float3(1, 0, 0))),
                                   	w.x),
                            	lerp(dot(pf - float3(0, 0, 1), hash33(pi + float3(0, 0, 1))), 
                                    dot(pf - float3(1, 0, 1), hash33(pi + float3(1, 0, 1))),
                                   	w.x),
                            	w.z),
                    		lerp(
                                lerp(dot(pf - float3(0, 1, 0), hash33(pi + float3(0, 1, 0))), 
                                    dot(pf - float3(1, 1, 0), hash33(pi + float3(1, 1, 0))),
                                   	w.x),
                               	lerp(dot(pf - float3(0, 1, 1), hash33(pi + float3(0, 1, 1))), 
                                    dot(pf - float3(1, 1, 1), hash33(pi + float3(1, 1, 1))),
                                   	w.x),
                            	w.z),
                			w.y);
            }
            
            float simplex_noise(float3 p)
            {
                const float K1 = 0.333333333;
                const float K2 = 0.166666667;
                
                float3 i = floor(p + (p.x + p.y + p.z) * K1);
                float3 d0 = p - (i - (i.x + i.y + i.z) * K2);
                
                // thx nikita: https://www.shadertoy.com/view/XsX3zB
                float3 e = step(float3(0.0,0.0,0.0), d0 - d0.yzx);
            	float3 i1 = e * (1.0 - e.zxy);
            	float3 i2 = 1.0 - e.zxy * (1.0 - e);
                
                float3 d1 = d0 - (i1 - 1.0 * K2);
                float3 d2 = d0 - (i2 - 2.0 * K2);
                float3 d3 = d0 - (1.0 - 3.0 * K2);
                
                float4 h = max(0.6 - float4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
                float4 n = h * h * h * h * float4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + 1.0)));
                
                return dot(float4(1.,1.,1.,1.)*31.316, n);
            }
            // return value noise (in x) and its derivatives (in yzw)
            float noise31( in float3 x )
            {
                // :: enable complex noise ::
                #if 1
                
                float c;
                // c = value_noise(x);
                c = perlin_noise(x + _Time.y * 0.5 * _WaveVelocity);
                // c = simplex_noise(x);
                
                return c;
                #else
                float3 i = floor(x);
                float3 f = frac(x);
                f = f*f*(3.0-2.0*f);
                return lerp(lerp(lerp( hash31(i+float3(0,0,0)), 
                                    hash31(i+float3(1,0,0)),f.x),
                               lerp( hash31(i+float3(0,1,0)), 
                                    hash31(i+float3(1,1,0)),f.x),f.y),
                           lerp(lerp( hash31(i+float3(0,0,1)), 
                                    hash31(i+float3(1,0,1)),f.x),
                               lerp( hash31(i+float3(0,1,1)), 
                                    hash31(i+float3(1,1,1)),f.x),f.y),f.z);
                #endif
            }

            float groundHeightMid(float2 uv)
            {
                float y=0.;
                //large wave
                float G=0.5;
                float A=10.0;
                
                // :: enable large wave ::
                float3 p=float3(uv,uv.x)*0.01+float3(.5,.5,.0)*_Time.y * _WaveVelocity;
                #if 1
        	    //A=5.;
                y+=A*(noise31(p));
                #endif
                
                // :: enable small wave ::
                #if 1
                //G=0.5;
        	    //A=5.;
                p=float3(uv,0.)*0.01+float3(.0,.1,.1)*_Time.y * _WaveVelocity;
                for(int i=0;i<3;++i){
                	y+=A*(1.-abs(noise31(p)-0.5)*2.);
                    p*=2.;
                    //p.xy=m2*p.xy;
                    p = (p.yzx + p.zyx*float3(1,-1,1))/sqrt(2.0);
                    A*=G;
                }
                #endif
                return y;
            }
            float groundHeightHigh(float2 uv)
            {
                float y=0.;
                //large wave
                float G=0.5;
                float A=10.0;
            
                //enable large wave
                float3 p=float3(uv,uv.x)*0.01+float3(.5,.5,.0)*_Time.y * _WaveVelocity;
                #if 1
            	//A=5.;
                y+=A*(noise31(p));
                #endif
                
                //enable small wave
                #if 1
                //G=0.5;
            	//A=5.;
                p=float3(uv,0.)*0.01+float3(.0,.1,.1)*_Time.y * _WaveVelocity;
                for(int i=0;i<8;++i){
                	y+=A*(1.-abs(noise31(p)-0.5)*2.);
                    p*=2.;
                    //p.xy=m2*p.xy;
                    p = (p.yzx + p.zyx*float3(1,-1,1))/sqrt(2.0);
                    A*=G;
                }
                #endif
                return y;
            }
            float3 getTerrianNormal(float2 uv,float t = 0.0)
            {
                //fix this
            	//const float e=1e-1;
                float e =max(.002*t,0.1);
                //float e =max(.00001*t*t,0.2);
                float3 N=normalize(float3(
                    groundHeightHigh(uv-float2(e,0.))-groundHeightHigh(uv+float2(e,0.)),
                    2.*e,		
                	groundHeightHigh(uv-float2(0.,e))-groundHeightHigh(uv+float2(0.,e)))
                );
                  
                return N;
            }

            

            Varyings vert (Attributes v)
            {
                Varyings o;
                
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);

                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionWS = o.positionWS + _HeightYScale * o.normalWS * groundHeightMid(v.uv * _HeightXZScale);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                
                o.uv = v.uv;
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                float3 col;
                
                Light mainLight = GetMainLight();
                float3 N = normalize(getTerrianNormal(i.uv * _NormalScale));
                // float3 N = normalize(i.normalWS);
                float3 L = normalize(mainLight.direction);
                float3 V = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                float3 H = normalize(L + V);
                float3 X = normalize(i.tangentWS);
                float3 Y = normalize(i.bitangentWS);

                float4 BaseColor = _BaseColor;

                // :: PBR ::
                float3 brdf_simple = BRDF_Simple(L, V, N, X, Y, BaseColor);
                float3 brdf_disney = BRDF_Disney(L, V, N, X, Y, BaseColor);
                float3 sss = SSS(L, V, N, BaseColor);

                float3 pbr_result = brdf_simple;

                // :: PBR Env Light ::
                float3 brdf_env_simple = BRDF_Indirect_Simple(L, V, N, X, Y, BaseColor);
                float3 brdf_env = BRDF_Indirect(L, V, N, X, Y, BaseColor);
                
                float3 env_result = brdf_env;

                // :: NPR ::
                float3 npr_color_2 = BaseColor * lerp(_NPR_Color1, _NPR_Color2, smoothstep(_RampOffset-_StepSmoothness, _RampOffset+_StepSmoothness, dot(N,L)/2 + 0.5));

                float3 npr_result = npr_color_2;

                col = _WeightPBR * pbr_result + _WeightEnvLight * env_result + _WeightNPR * npr_result;
                
                return float4(col, 1);
            }
            ENDHLSL
        }
    }
}
