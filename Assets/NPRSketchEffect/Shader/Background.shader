Shader "NPR Sketch Effect/Background" {
	Properties {
		[NoScaleOffset]_MainTex ("Background", 2D) = "white" {}
	}
	SubShader {
		Pass {
			Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }
			Cull Back

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			struct v2f
			{
				float4 pos : POSITION;
				float4 posscr : TEXCOORD0;
			};
			v2f vert (appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.posscr = ComputeScreenPos(o.pos);
				return o;
			}
			float4 frag (v2f input) : COLOR
			{
				float2 uv = input.posscr.xy / input.posscr.w;
				return tex2D(_MainTex, uv);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}