﻿Shader "NPR Sketch Effect/Pencil Contour" {
	Properties {
		[HideInInspector]_MainTex ("Base (RGB)", 2D) = "white" {}
		[NoScaleOffset]_NoiseTex ("Noise Tex", 2D) = "black" {}
		_NoiseUvScale ("Noise Uv Scale", Float) = 1.0
		_Speed ("Speed", Float) = 1.0
		_ErrorPeriod ("Error Period", Float) = 25.0
		_ErrorRange ("Error Range", Float) = 0.0015
		_NoiseAmount ("Noise Amount", Float) = 0.02
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
		_SampleDistance ("Sample Distance", Float) = 1.0
	}
	SubShader {
		CGINCLUDE
		#include "UnityCG.cginc"
		sampler2D _MainTex, _NoiseTex, _CameraDepthTexture, _EdgeTex;
		float4 _MainTex_TexelSize, _EdgeColor, _BackgroundColor;
		float _ErrorPeriod, _ErrorRange, _NoiseAmount, _EdgeOnly, _SampleDistance, _NoiseUvScale, _Speed;
		// sobel filter edge detection ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
		struct v2fSobel
		{
			float4 pos : SV_POSITION;
			float2 uv[10]: TEXCOORD0;
		};
		v2fSobel vertSobel (appdata_img v)
		{
			v2fSobel o;
			o.pos = UnityObjectToClipPos(v.vertex);

			float2 uv = v.texcoord;
			o.uv[0] = uv;
#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				uv.y = 1 - uv.y;
#endif
			o.uv[1] = uv;
			o.uv[2] = uv + _MainTex_TexelSize.xy * float2(-1, 1) * _SampleDistance;  // TL
			o.uv[3] = uv + _MainTex_TexelSize.xy * float2( 1, 1) * _SampleDistance;  // TR
			o.uv[4] = uv + _MainTex_TexelSize.xy * float2(-1,-1) * _SampleDistance;  // BL
			o.uv[5] = uv + _MainTex_TexelSize.xy * float2( 1,-1) * _SampleDistance;  // BR
			o.uv[6] = uv + _MainTex_TexelSize.xy * float2( 0, 1) * _SampleDistance;  // T
			o.uv[7] = uv + _MainTex_TexelSize.xy * float2( 1, 0) * _SampleDistance;  // R
			o.uv[8] = uv + _MainTex_TexelSize.xy * float2( 0,-1) * _SampleDistance;  // B
			o.uv[9] = uv + _MainTex_TexelSize.xy * float2(-1, 0) * _SampleDistance;  // L
			return o;
		}
		float4 fragSobelDepthThin (v2fSobel i) : SV_Target
		{
			float center = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[1]));

			float4 diag, axis;
			diag.x = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[2]));
			diag.y = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[3]));
			diag.z = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[4]));
			diag.w = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[5]));
			axis.x = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[6]));
			axis.y = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[7]));
			axis.z = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[8]));
			axis.w = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[9]));
			
			diag = (diag > center.xxxx) ? diag : center.xxxx;
			axis = (axis > center.xxxx) ? axis : center.xxxx;
			
			diag /= center;
			axis /= center;
			
			float4 horizDiag = float4(-1, -1,  1,  1);
			float4 horizAxis = float4(-2,  0,  2,  0);
			float4 vertDiag  = float4(-1,  1, -1,  1);
			float4 vertAxis  = float4( 0,  2,  0, -2);
			
			float h = dot(diag, horizDiag) + dot(axis, horizAxis);
			float v = dot(diag, vertDiag) + dot(axis, vertAxis);
			float edge = 1 - pow(saturate(sqrt(h * h + v * v)), 2);
			return float4(edge.xxx, 1);
		}
		// pencil contour /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		struct v2fContour
		{
			float4 pos : SV_POSITION;
			float2 uv[2]: TEXCOORD0;
		};
		v2fContour vertContour (appdata_img v)
		{
			v2fContour o;
			o.pos = UnityObjectToClipPos(v.vertex);

			float2 uv = v.texcoord;
			o.uv[0] = uv;
#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				uv.y = 1 - uv.y;
#endif
			o.uv[1] = uv;
			return o;
		}
		float4 fragContour (v2fContour i) : SV_Target
		{
			float n = (tex2D(_NoiseTex, i.uv[0] * _NoiseUvScale + _Time.y * _Speed).x - 0.5) * _NoiseAmount;
			float2 uv[3];
			uv[0] = i.uv[1] + float2(_ErrorRange * sin(_ErrorPeriod * i.uv[1].y + 0.0  ) + n, _ErrorRange * sin(_ErrorPeriod * i.uv[1].x + 0.0  ) + n);
			uv[1] = i.uv[1] + float2(_ErrorRange * sin(_ErrorPeriod * i.uv[1].y + 1.047) + n, _ErrorRange * sin(_ErrorPeriod * i.uv[1].x + 3.142) + n);
			uv[2] = i.uv[1] + float2(_ErrorRange * sin(_ErrorPeriod * i.uv[1].y + 2.094) + n, _ErrorRange * sin(_ErrorPeriod * i.uv[1].x + 1.571) + n);

			float3 edge = tex2D(_EdgeTex, uv[0]).r * tex2D(_EdgeTex, uv[1]).r * tex2D(_EdgeTex, uv[2]).r;
			float3 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge).rgb;
			float3 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge).rgb;

			return float4(lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly), 1.0);
		}
		ENDCG
		Pass {   // 0
			ZTest Always Cull Off ZWrite Off
			CGPROGRAM
			#pragma vertex vertSobel
			#pragma fragment fragSobelDepthThin
			ENDCG  
		}
		Pass {   // 1
			ZTest Always Cull Off ZWrite Off
			CGPROGRAM
			#pragma vertex vertContour
			#pragma fragment fragContour
			ENDCG
		}
	}
	FallBack Off
}
