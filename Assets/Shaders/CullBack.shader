Shader "Cel/OutlineSample"
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
        _RampTex("Ramp", 2D) = "white" {}
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
            CBUFFER_END
            TEXTURE2D(_BaseMap);                 
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);
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