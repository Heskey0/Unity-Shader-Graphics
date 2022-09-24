Shader "Custom/PBR_Raw"
{
    Properties
    {
        _MainTex ("BaseColor", 2D) = "white" {}
        
        
        [Header(PBR Light)][Space(10)]
        _WeightPBR("Weight PBR", Range(0, 1))=1.0
        _DiffusePBR("Diffuse PBR", Range(0, 1)) = 0.3
        _roughness       ("Roughness"    , Range(0, 1)) = 0.5
        _metallic        ("Metallic"     , Range(0, 1)) = 0.5
        _subsurface      ("Subsurface"   , Range(0, 1)) = 0.5
        _anisotropic     ("Anisotropic"  , Range(0, 1)) = 0.5
        _specular        ("Specular"     , Range(0, 1)) = 0.5
        _specularTint    ("Specular Tint", Range(0, 1)) = 0.5
        _sheenTint       ("Sheen Tint"   , Range(0, 1)) = 0.5
        _sheen           ("Sheen"        , Range(0, 1)) = 0.5
        _clearcoat       ("Clearcoar"    , Range(0, 1)) = 0.5
        _clearcoatGloss  ("Clearcoat Gloss", Range(0, 1)) = 0.5
        _ior             ("index of refraction", Range(0, 10)) = 3
        
        
        [Header(Env Light)][Space(10)]
        _WeightEnvLight("Weight EnvLight", Range(0, 1)) = 0.1
        [NoScaleOffset] _Cubemap ("Envmap", cube) = "_Skybox" {}
        _CubemapMip ("Envmap Mip", Range(0, 7)) = 0
        _IBL_LUT("Precomputed integral LUT", 2D) = "white" {}
        _FresnelPow ("FresnelPow", Range(0, 5)) = 1
        _FresnelColor ("FresnelColor", Color) = (1,1,1,1)
        
        
        [Header(Rim Light)][Space(10)]
        _RimThickness ("Thickness", Range(0.8, 0.99999)) = 0.88
        _RimOffset ("RimOffset", Range(0, 1)) = 0.36
        _RimCol     ("Rim Color", Color) = (1, 1, 1, 1)
        
        
        _ZOffset("Depth Offset", Range(-500, 500)) = 0
    }
    SubShader
    {
        // Depth
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
        
        // Shading
        Pass
        {
            Tags 
            { 
                "RenderPipiline"="UniversalPipeline"
                "RenderType"="Opaque"
            }
            
            ZWrite On
            Offset [_ZOffset], 0
            
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

            // RimLight
            float _RimThickness;
            float _RimOffset;
            float4 _RimCol;
            
            // EnvLight
            float _WeightEnvLight;
            samplerCUBE _Cubemap;
            float _CubemapMip;
            float _FresnelPow;
            float4 _FresnelColor;

            TEXTURE2D(_IBL_LUT);
            SAMPLER(sampler_IBL_LUT);

            CBUFFER_START(UnityPerMaterial)

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            CBUFFER_END
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS : POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float3 tangentWS : TEXCOORD4;
                float3 bitangentWS : TEXCOORD5;
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

            
            Varyings vert(Attributes v)
            {
                Varyings o;
                o.uv = v.uv;
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.screenPos = ComputeScreenPos(o.positionCS);

                o.tangentWS = normalize(mul(unity_ObjectToWorld, float4(v.tangentOS.xyz, 0.0)).xyz);
                o.bitangentWS = normalize(cross(o.normalWS, o.tangentWS) * v.tangentOS.w);

                return o;
            }
            

            float4 frag(Varyings i) : SV_TARGET
            {
                float4 o = (0,0,0,1);
                
                // :: initialize ::
                Light mainLight = GetMainLight();
                float3 N = normalize(i.normalWS);
                float3 L = normalize(mainLight.direction);
                float3 V = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                float3 H = normalize(L + V);
                float3 X = normalize(i.tangentWS);
                float3 Y = normalize(i.bitangentWS);
                
                float NdotL = dot(N, L);
                float NdotV = dot(N, V);
                float VdotH = dot(V, H);

                float4 BaseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                
                
                float3 Front = unity_ObjectToWorld._12_22_32;	// 角色朝向

                // :: PBR ::
                float3 brdf_simple = BRDF_Simple(L, V, N, X, Y, BaseColor);
                float3 brdf_disney = BRDF_Disney(L, V, N, X, Y, BaseColor);
                float3 sss = SSS(L, V, N, BaseColor);

                float3 pbr_result = brdf_simple;
                

                // :: PBR Env Light ::
                float3 brdf_env_simple = BRDF_Indirect_Simple(L, V, N, X, Y, BaseColor);
                float3 brdf_env = BRDF_Indirect(L, V, N, X, Y, BaseColor);
                
                float3 env_result = brdf_env;

                
                // :: Rim Light ::
                float3 normalVS = mul(UNITY_MATRIX_V, float4(N, 0.0)).xyz;
                float2 screenPos01 = i.screenPos.xy / i.screenPos.w;
                
                float2 ScreenUV_Ori = float2(i.positionCS.x / _ScreenParams.x, i.positionCS.y / _ScreenParams.y);
                float2 ScreenUV_Off = ScreenUV_Ori + normalVS.xy * _RimOffset*0.01;
                
                float depthTex_Ori = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, ScreenUV_Ori);
                float depthTex_Off = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, ScreenUV_Off);

                float depthOri = Linear01Depth(depthTex_Ori, _ZBufferParams);
                float depthOff = Linear01Depth(depthTex_Off, _ZBufferParams);

                float RimThreshold = 1 - _RimThickness;
                float diff = depthOff-depthOri;
                float rimMask = smoothstep(RimThreshold * 0.001f, RimThreshold * 0.0015f, diff);

                o.xyz = _WeightPBR * pbr_result + _WeightEnvLight * env_result;
                o.xyz = max(o.xyz, rimMask * _RimCol.xyz);
                
                return o;
            }

            ENDHLSL
        }
        
        // Shadow
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5
            
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

            #ifndef UNIVERSAL_SHADOW_CASTER_PASS_INCLUDED
            #define UNIVERSAL_SHADOW_CASTER_PASS_INCLUDED
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            float3 _LightDirection;
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
            };
            
            float4 GetShadowPositionHClipSpace(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
            
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
            
                return positionCS;
            
            }
            
            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
            
                output.positionCS = GetShadowPositionHClipSpace(input);
                return output;
            }
            
            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                return 0;
            }
            
            #endif


            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
