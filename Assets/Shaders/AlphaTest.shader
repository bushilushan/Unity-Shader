Shader "MyShaders/AlphaTest" {
	Properties {
		_Color("Main Tint", Color) = (1, 1, 1, 1)
		_MainTex("Main Texture", 2D) = "white" {}
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.7
	}
	SubShader {
		// Queue定义了渲染顺序。这里我们想要使用AlphaTest，所以设置为AlphaTest队列。
		// RenderType定义了渲染类型，有Opaque、Transparent、TransparentCutout等。对于需要透明度测试的物体，我们一般使用TransparentCutout。
		// IgnoreProjector定义了是否忽略投影。对于不需要投影的物体，我们一般设置为True。
		// 在Unity中，投影器（Projector）是一个组件，用于将材质或纹理投影到与其视锥体相交的所有对象上。
		// 它的工作原理类似于现实世界中的投影仪，可以将纹理或材质投射到场景中的物体表面
		// 作用和应用
		// 创建阴影：投影器常用于生成阴影效果。通过将阴影纹理投影到物体上，可以模拟光源的阴影。
		// 弹痕效果：可以用于在物体表面创建弹痕或其他类型的贴花效果。
		// 光照效果：可以用来模拟特殊的光照效果，例如聚光灯或光斑。
		// 为什么忽略投影器？
		// 主要是因为透明度渲染的特殊性导致投影器的效果可能不适用或产生不理想的视觉效果。
		// 例如，假设有一个半透明的物体，当使用透明度测试时，只有透明度高于某个阈值的部分才会被渲染。如果投影器的效果被应用到这个物体上，可能会导致一些不透明的部分被错误地渲染出来，因为投影器通常会影响整个物体表面，而不是基于透明度阈值进行区分。
		// 例如，一个半透明的玻璃窗，透过它可以看到背后的物体。如果投影器的效果被应用到这个玻璃窗上，投影器的光可能会与玻璃窗的半透明效果混合，导致视觉上的不一致或不自然
		Tags { "RenderType" = "TransparentCutout" "Queue" = "AlphaTest" "IgnoreProjector" = "True"}
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
				
			#include "Lighting.cginc"

			// 对应于Properties中的属性
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float _Cutoff;

			// 顶点着色器
			struct a2v {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}

			// 片段着色器
			float4 frag(v2f i) : SV_Target {
				float4 texColor = tex2D(_MainTex, i.uv);
				float3 normalDir = normalize(i.worldNormal);
				float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				// 透明度测试
				clip(texColor.a - _Cutoff);

				fixed3 albedo = texColor.rgb * _Color.rgb;
				// 环境光
				float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				// 漫反射
				float3 diffuse = _LightColor0.rgb * max(0, dot(normalDir, lightDir));

				return float4(ambient + diffuse, 1);
			}

			ENDCG
		}
	}
	FallBack "Transparent/Cutout/VertexLit"
}