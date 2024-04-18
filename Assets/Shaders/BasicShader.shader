Shader "Cel/Base"
{
    Properties
    {
        _BaseMap ("BaseMap", 2D) = "white" {}
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _ShadowColor("Shadow Color", Color) = (0,0,0,1)
        _OutlineWidth("OutlineWidth", Range(0, 10)) = 0.4
        _Cutoff("Cutoff", Range(0, 1))=0.5
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        _SpecularScale("Specular Scale", Range(0,1)) = 0.01
        //_ShadowRange("Shadow Range", Range(0, 1)) = 0.5
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RampTex("Ramp", 2D) = "white" {}
        _RimMin("Rim Min", Range(0, 1)) = 0.9
        _RimMax("Rim Max", Range(0, 1)) = 1
        _RimSmooth("Rim Smooth", Range(0, 1)) = 0.5
        [Toggle(SPEC_ON)] _Spec ("Specular Highlight", Float) = 0
        [Toggle(ANI_ON)] _SpecAn ("Anisotropy Highlight", Float) = 0
        [Toggle(SSS_ON)] _SSS ("Sub-Surface Shatter", Float) = 0
        _SSSStrength("SSS Strength", Range(0, 1)) = 0.5
        _SpecularPosition("Anisotropy Specular Position", Range(-1, 1)) = 0
        _SpecularExponent("Anisotropy Specular Exponent", Range(0, 500)) = 50
        _SpecularStrength("Anisotropy Specular Strength", Range(0, 1)) = 0.5
        _NoiseTex("Noise", 2D) = "white" {}
        _SSSLUTTex("SSS LUT", 2D) = "white" {}
        _SSSColor("SSS Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"         
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _Cutoff;
                //float _ShadowRange;
                float4 _BaseColor;
                float4 _ShadowColor;
                float _OutlineWidth;
                float4 _OutlineColor;
                float4 _SpecularColor;
                float _SpecularScale;
                float _SpecularPosition;
                float _SpecularExponent;
                float _SpecularStrength;
                float4 _RimColor;
                float4 _SSSColor;
                float _RimMin;
                float _RimMax;
                float _RimSmooth;
                float _SSSStrength;
            CBUFFER_END
            TEXTURE2D(_BaseMap);                 
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_SSSLUTTex);
            SAMPLER(sampler_SSSLUTTex);
            struct Attributes{
                float4 positionOS : POSITION;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 texcoord : TEXCOORD;
            };
            struct Varyings{
                float3 positionWS : TEXCOORD3;
                float4 positionCS : SV_POSITION;
                float3 bitangentWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };
        ENDHLSL
        Pass 
        {
            Tags{"LightMode" = "UniversalForward"} 
            Cull back
            HLSLPROGRAM
	        #pragma target 3.0
            #pragma vertex vert0
            #pragma fragment frag0
            #pragma shader_feature SPEC_ON
            #pragma shader_feature ANI_ON
            #pragma shader_feature SSS_ON
            Varyings vert0(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.bitangentWS = normalInput.bitangentWS;
                output.uv = input.texcoord.xy;
                return output;
            }
            float4 frag0(Varyings input):SV_Target
            {
                float4 BaseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,input.uv);
                // Diffuse Lighting using Lambert Model
                Light light = GetMainLight();
                float halfLambert = dot(input.normalWS, light.direction)*0.5 +0.5;
                float ramp = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex, float2(saturate(halfLambert), 0.5)).r;
                float3 diffuseColor = lerp(_ShadowColor.rgb, _BaseColor.rgb, ramp);
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0; lightIndex < pixelLightCount; ++lightIndex){
                    Light light = GetAdditionalLight(lightIndex, input.positionWS);
                    float halfLambert = dot(input.normalWS, light.direction);
                    float ramp = SAMPLE_TEXTURE2D(_RampTex,sampler_RampTex, float2(saturate(halfLambert), 0.5)).r;
                    diffuseColor += lerp(_ShadowColor.rgb, _BaseColor.rgb, ramp);
                }
                light = GetMainLight();
                float3 specular = 0;
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                float3 halfDir = normalize(light.direction + viewDir);
                
                #ifdef SPEC_ON
                // Highlight using Blinn-Phong Model
                float NdotH = dot(input.normalWS, halfDir);
                float spec =  step(1-_SpecularScale,NdotH);
                specular = light.color.rgb * _SpecularColor.rgb * spec;
                #endif

                #ifdef ANI_ON
                // Highlight using Kajiya-Kay Model
                float Noise = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,input.uv).r;
                float3 tangentDir = normalize(input.bitangentWS + (_SpecularPosition * 2 - 1 + (1 - Noise)) * input.normalWS );
                float TdotH = dot(tangentDir, halfDir);
                float sinTH = sqrt(1.0 - TdotH * TdotH);
                float dirAtten = smoothstep(-1.0, 0.0, TdotH);
                float spec = dirAtten * pow(sinTH, _SpecularExponent) * _SpecularStrength;
                specular = light.color.rgb * _SpecularColor.rgb * spec;
                #endif

                // Rim Lighting
                float fresnel  = 1.0 - saturate(dot(viewDir, input.normalWS));
                float rim = smoothstep(_RimMin, _RimMax, fresnel);
                rim = smoothstep(0, _RimSmooth, rim);
                float3 rimColor = rim * _RimColor.rgb * _RimColor.a;


                float3 sssColor = 0;
                #ifdef SSS_ON
                float b = dot(input.normalWS, light.direction)*0.5 +0.5;
                sssColor = SAMPLE_TEXTURE2D(_SSSLUTTex,sampler_SSSLUTTex, float2(saturate(b), 0.1)).r * _SSSStrength * _SSSColor.rgb;
                // Subsurface Scattering
                #endif


                float3 color = BaseMap.rgb * diffuseColor + specular + rimColor + sssColor;
                clip(BaseMap.a-_Cutoff);
                return float4(color,1);

                
            }
            ENDHLSL
        }
        Pass {
            Name "OutLine"
            Tags{ "LightMode" = "SRPDefaultUnlit" }
	    Cull front
	    HLSLPROGRAM
	    #pragma vertex vert1  
	    #pragma fragment frag1
	    Varyings vert1(Attributes input) {
                Varyings output;
                float4 scaledScreenParams = GetScaledScreenParams();
                float ScaleX = abs(scaledScreenParams.x / scaledScreenParams.y);
		        VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
                float3 normalCS = TransformWorldToHClipDir(normalInput.normalWS);
                float2 extendDis = normalize(normalCS.xy) *(_OutlineWidth*0.01);
                extendDis.x /=ScaleX ;
                output.positionCS = vertexInput.positionCS;
                output.positionCS.xy +=extendDis;
		        return output;
	     }
	     float4 frag1(Varyings input) : SV_Target {
                 return float4(_OutlineColor.rgb, 1);
	     }
	     ENDHLSL
         }
    }
    Fallback "Universal Render Pipeline/Lit"
}