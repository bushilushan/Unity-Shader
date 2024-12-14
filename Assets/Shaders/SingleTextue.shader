Shader "MyShader/BlinnPhongLightMode" {

	Properties {
		_MainTex ("Texture", 2D) = "white" {}
		// 我们不再需要漫反射颜色，我们使用纹理采样得到的颜色来代替漫反射颜色
		// _DiffuseColor ("Diffuse", Color) = (1, 1, 1, 1)
		// 扩展知识：在声明属性前添加[HideInInspector]特性，可以隐藏该属性在Inspector面板中显示
		_SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(1.0, 500)) = 20
	}

	SubShader {
		Pass {
			Tags { "RenderType"="Opaque" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			sampler2D _MainTex;
			// _MainTex_ST 是一个四维的 float4 变量，通常用于存储纹理的平铺（前两个分量）和偏移（后两个分量）。
			float4 _MainTex_ST;
			// fixed4 _DiffuseColor;
			fixed4 _SpecularColor = fixed4(1, 1, 1, 1);
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float4 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				// tiling and Offset
				// TRANSFORM_TEX函数会尝试调用_MainTex_ST，所以前面我们需要声明_MainTex_ST
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				// sample the texture
				fixed4 tex_col = tex2D(_MainTex, i.uv);
				// ambient
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * tex_col.rgb;
				// diffuse
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 diffuse = _LightColor0.rgb * tex_col.rgb * max(0, dot(worldNormal, worldLightDir));
				// specular
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _SpecularColor.xyz * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	}

	FallBack "Specular"
}