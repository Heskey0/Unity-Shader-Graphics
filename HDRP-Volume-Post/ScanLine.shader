Shader "Hidden/Shader/ScanLine"
{
    Properties
    {
        // This property is necessary to make the CommandBuffer.Blit bind the source texture to _MainTex
        _MainTex("Main Texture", 2DArray) = "grey" {}
    }

    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/FXAA.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/RTUpscale.hlsl"

    float2 grad( int2 z )  // replace this anything that returns a random vector
    {
        // 2D to 1D  (feel free to replace by some other)
        int n = z.x+z.y*11111;
    
        // Hugo Elias hash (feel free to replace by another one)
        n = (n<<13)^n;
        n = (n*(n*n*15731+789221)+1376312589)>>16;
    
    #if 0
    
        // simple random vectors
        return float2(cos(float(n)),sin(float(n)));
        
    #else
    
        // Perlin style vectors
        n &= 7;
        float2 gr = float2(n&1,n>>1)*2.0-1.0;
        return ( n>=6 ) ? float2(0.0,gr.x) : 
               ( n>=4 ) ? float2(gr.x,0.0) :
                                  gr;
    #endif                              
    }
    float GradientNoise( in float2 p )
    {
        int2 i = int2(floor( p ));
         float2 f =       frac( p );
    	
    	float2 u = f*f*(3.0-2.0*f); // feel free to replace by a quintic smoothstep instead
    
        return lerp( lerp( dot( grad( i+int2(0,0) ), f-float2(0.0,0.0) ), 
                         dot( grad( i+int2(1,0) ), f-float2(1.0,0.0) ), u.x),
                    lerp( dot( grad( i+int2(0,1) ), f-float2(0.0,1.0) ), 
                         dot( grad( i+int2(1,1) ), f-float2(1.0,1.0) ), u.x), u.y);
    }


    struct Attributes
    {
        uint vertexID : SV_VertexID;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float2 texcoord   : TEXCOORD0;
        UNITY_VERTEX_OUTPUT_STEREO

    };

    Varyings Vert(Attributes input)
    {
        Varyings output;

        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);

        return output;
    }

    // List of properties to control your post process effect
    float _Radius;
    float _Width;
    float4 _Center;
    float4 _Color;
    float4 _Color_End;
    TEXTURE2D_X(_MainTex);

    float4 CustomPostProcess(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        float4 fragColor = float4(1,1,1,1);

        _Radius = pow(frac(_Radius + _Time.y*0.1f), 2);

        float3 sourceColor = SAMPLE_TEXTURE2D_X(_MainTex, s_linear_clamp_sampler, input.texcoord).xyz;

        float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, input.texcoord).x;
        float3 worldPos = ComputeWorldSpacePosition(input.texcoord, depth, UNITY_MATRIX_I_VP);
        worldPos += _WorldSpaceCameraPos;
        

        // :: Test ::
        // uint scale = 10;
        // // Scale, mirror and snap the coordinates.
        // uint3 worldIntPos = uint3(abs(worldPos.xyz * scale));
        // // Divide the surface into squares. Calculate the color ID value.
        // bool white = ((worldIntPos.x) & 1) ^ (worldIntPos.y & 1) ^ (worldIntPos.z & 1);
        // // Color the square based on the ID value (black or white).
        // half4 color = white ? half4(1,1,1,1) : half4(0,0,0,1);
        //
        // // Set the color to black in the proximity to the far clipping
        // if(depth < 0.0001)
        //     return half4(0,0,0,1);
        //
        // fragColor = color;

        
        fragColor.xyz = length(worldPos);

        float maxDis = 500.0f;
        float dis = distance(worldPos, _Center) / maxDis;
        float delta = smoothstep(_Radius-_Width, _Radius+_Width, dis)*(1-step(_Radius, dis));

        fragColor.xyz = sourceColor + pow(delta * lerp(_Color*3.0, _Color_End*3.0, dis * 20.f), 3.0);
        return fragColor;
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "ScanLine"

            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            HLSLPROGRAM
                #pragma fragment CustomPostProcess
                #pragma vertex Vert
            ENDHLSL
        }
    }

    Fallback Off
}