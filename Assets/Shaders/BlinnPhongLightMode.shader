Shader "MyShader/BlinnPhongLightMode" {

	Properties {
		_DiffuseColor ("Diffuse", Color) = (1, 1, 1, 1)
		_SpecularColor ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(1.0, 500)) = 20
	}

	// per pixel lighting
	SubShader {
		Pass {
			// 标签如果使用下面这个标签，模型会直接变紫色，不知道什么原因
			// Tags { "LightMode"="ForwardBase" }
			Tags { "RenderType"="Opaque" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _DiffuseColor;
			fixed4 _SpecularColor;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float4 worldPos : TEXCOORD1;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				// ambient
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				// diffuse
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 diffuse = _LightColor0.rgb * _DiffuseColor.rgb * max(0, dot(worldNormal, worldLightDir));
				// specular
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	}

	// per vertex lighting（使用逐顶点进行光照计算，在明暗交接处会有明显的不规则锯齿，效果很不好，所以一般不推荐）
	SubShader {
		Pass { 
			Tags { "RenderType"="Opaque" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _DiffuseColor;
			fixed4 _SpecularColor;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 color : COLOR;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				// ambient
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				// diffuse
				fixed3 worldNormal = normalize(v.normal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(v.vertex));
				fixed3 diffuse = _LightColor0.rgb * _DiffuseColor.rgb * max(0, dot(worldNormal, worldLightDir));
				// specular
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(v.vertex));
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				
				o.color = ambient + diffuse + specular;
				return o;
			}
			
			fixed3 frag(v2f i) : SV_Target {
				return i.color;
			}
			
			ENDCG
		}
	}

	FallBack "Specular"
}