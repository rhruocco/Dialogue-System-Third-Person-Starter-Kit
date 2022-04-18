Shader "NPR Sketch Effect/Sketch" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		_Sketch0Tex ("Sketch 0 Tex", 2D) = "white" {}
		_Sketch1Tex ("Sketch 1 Tex", 2D) = "white" {}
		_Sketch2Tex ("Sketch 2 Tex", 2D) = "white" {}
		_Sketch3Tex ("Sketch 3 Tex", 2D) = "white" {}
		_Sketch4Tex ("Sketch 4 Tex", 2D) = "white" {}
		_Sketch5Tex ("Sketch 5 Tex", 2D) = "white" {}
		_SketchColor ("Sketch Color", Color) = (0, 0, 0, 0)
		_Intensity ("Main Tex Intensity", Range(0.5, 2)) = 1
		_Tile ("Sketch Tile", Range(1, 10)) = 5
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 0)
		_OutlineWidth ("Outline Width", Float) = 0.005
		_ExpandFactor ("Outline Factor", Range(0, 1)) = 1
//		_OffsetFactor ("Offset Factor", Range(-1, 1)) = 0
//		_OffsetUnits  ("Offset Units", Range(-1, 1)) = 0
		_RefValue     ("Stencil Ref", Int) = 1
	}
	SubShader {
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry+1" "LightMode" = "ForwardBase" }
		Pass {
			Stencil
			{
				Ref [_RefValue]
				Comp Always
				Pass Replace
			}
			Cull Back Zwrite On

			CGPROGRAM
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag

			sampler2D _MainTex, _Sketch0Tex, _Sketch1Tex, _Sketch2Tex, _Sketch3Tex, _Sketch4Tex, _Sketch5Tex;
			float4 _MainTex_ST, _SketchColor;
			float _Intensity, _Tile;

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 tex : TEXCOORD0;
				float4 scrpos : TEXCOORD1;
				float3 wldnor : TEXCOORD2;
				float3 wldlit : TEXCOORD3;
				LIGHTING_COORDS(4, 5)
			};
			v2f vert (appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.tex = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.scrpos = ComputeScreenPos(o.pos);
				o.wldnor = mul((float3x3)unity_ObjectToWorld, v.normal);
				o.wldlit = WorldSpaceLightDir(v.vertex);
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}
			float4 frag (v2f input) : SV_Target
			{
				float3 N = normalize(input.wldnor);
				float3 L = normalize(input.wldlit);
				float2 scrpos = input.scrpos.xy / input.scrpos.w * _Tile;
				float atten = LIGHT_ATTENUATION(input);

//				float diff = (dot(N, L) * 0.5 + 0.5) * atten * 6.0;
				float diff = dot(N, L) * atten * 6.0;
				float3 c = 0.0;
				if (diff < 1.0)
					c = tex2D(_Sketch5Tex, scrpos).rgb;
				else if (diff < 2.0)
					c = tex2D(_Sketch4Tex, scrpos).rgb;
				else if (diff < 3.0)
					c = tex2D(_Sketch3Tex, scrpos).rgb;
				else if (diff < 4.0)
					c = tex2D(_Sketch2Tex, scrpos).rgb;
				else if (diff < 5.0)
					c = tex2D(_Sketch1Tex, scrpos).rgb;
				else
					c = tex2D(_Sketch0Tex, scrpos).rgb;
				float4 sketchColor = lerp(_SketchColor, 1.0, c.r);

				float4 albedo = tex2D(_MainTex, input.tex) * _Intensity;
				return float4(sketchColor * albedo.rgb, 1.0) * _LightColor0;
			}
			ENDCG
		}
		Pass {
			Stencil
			{
				Ref [_RefValue]
				Comp NotEqual
			}
			//Cull Front Zwrite On Offset [_OffsetFactor], [_OffsetUnits]
			Cull Front Zwrite Off

			CGPROGRAM
			#include "UnityCG.cginc"
			#pragma vertex vert
			#pragma fragment frag

			float4 _OutlineColor;
			float _OutlineWidth, _ExpandFactor;
			struct v2f
			{
				float4 pos : SV_POSITION;
			};
			v2f vert (appdata_base v)
			{
				float3 dir1 = normalize(v.vertex.xyz);
				float3 dir2 = v.normal;
				float3 dir = lerp(dir1, dir2, _ExpandFactor);
				dir = mul((float3x3)UNITY_MATRIX_IT_MV, dir);
				float2 offset = normalize(TransformViewToProjection(dir.xy));
				float dist = distance(mul(unity_ObjectToWorld, v.vertex), _WorldSpaceCameraPos);

				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
#if UNITY_VERSION > 540
				o.pos.xy += offset * o.pos.z * _OutlineWidth * dist;
#else
				o.pos.xy += offset * o.pos.z * _OutlineWidth / dist;
#endif
				return o;
			}
			half4 frag (v2f input) : SV_Target
			{
				return _OutlineColor;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"  // need this to generate correct depth buffer
}
