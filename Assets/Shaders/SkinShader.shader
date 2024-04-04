Shader "Cel/Skin"
{
    Properties
    {
        _BaseMap ("BaseMap", 2D) = "white" {}
        _BaseColor("Base Light Color",Color) = (1,1,1,1)
        _BaseShadowColor("Base Shadow Color",Color) = (1,1,1,1)
        // _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _OutlineWidth("OutlineWidth", Range(0, 10)) = 0.4
        _Cutoff("Cutoff", Range(0, 1))=0.5
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        // _SpecularScale("Specular Scale", Range(0,1)) = 0.01
        _ShadowRange("Shadow Range", Range(0, 1)) = 0.5
    }
    SubShader
    {
        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"         
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _Cutoff;
                float _ShadowRange;
                float4 _BaseColor;
                float4 _BaseShadowColor;
                float _OutlineWidth;
                float4 _OutlineColor;
                float4 _SpecularColor;
                float _SpecularScale;
            CBUFFER_END
            TEXTURE2D(_BaseMap);                 
            SAMPLER(sampler_BaseMap);
            struct Attributes{
                float4 positionOS : POSITION;
                float4 normalOS : NORMAL;
                float4 texcoord : TEXCOORD;
            };
            struct Varyings{
                float3 positionWS : TEXCOORD3;
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };
        ENDHLSL
        Pass 
        {
            Tags{"LightMode" = "UniversalForward"} 
            Cull off
            HLSLPROGRAM
	    #pragma target 3.0
            #pragma vertex vert0
            #pragma fragment frag0
            Varyings vert0(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.uv = input.texcoord.xy;
                return output;
            }
            float4 frag0(Varyings input):SV_Target
            {
                float4 BaseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,input.uv);
                // Diffuse Lighting using Lambert's
                Light light = GetMainLight();
                float diffuse = dot(input.normalWS, light.direction);
                diffuse = diffuse*0.5 +0.5;
                diffuse = saturate(diffuse);
                float shadowRange = step(_ShadowRange, diffuse); 
                float3 diffuseColor = light.color.rgb * shadowRange + _BaseShadowColor.rgb * (1-shadowRange);
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0; lightIndex < pixelLightCount; ++lightIndex){
                    Light light = GetAdditionalLight(lightIndex, input.positionWS);
                    float diffuse = dot(input.normalWS, light.direction);
                    diffuse = diffuse*0.5 +0.5;
                    diffuse = saturate(diffuse);
                    shadowRange = step(_ShadowRange, diffuse);
                    diffuseColor += light.color.rgb * shadowRange + _BaseShadowColor.rgb * (1-shadowRange);
                }
                // Highlight using Blinn-Phong
                // light = GetMainLight();
                // float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                // float3 halfDir = normalize(light.direction + viewDir);
                // float NdotH = dot(input.normalWS, halfDir);
                // float spec =  step(1-_SpecularScale,NdotH);
                // float3 specular = light.color.rgb * _SpecularColor.rgb * spec;

                float3 color = BaseMap.rgb * _BaseColor.rgb * diffuseColor;
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