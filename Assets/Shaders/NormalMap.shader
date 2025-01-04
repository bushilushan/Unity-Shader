Shader "MyShaders/NormalMapTangentSpace"{
	Properties{
		_MainTex("Texture", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Range(0, 10)) = 1
		_SpecularColor("SpecularColor", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(0, 50)) = 30
	}

	// 在切线空间下进行法线贴图的处理，先在顶点着色器中将世界空间的视角方向、光线方向转化到切线空间，
	// 然后在片段着色器中采样采样切线空间中的法线并使用光照模型计算光照。
	SubShader{
		Pass{
			Tags{"RenderType" = "Opaque"}
			CGPROGRAM
	
			#include "Lighting.cginc"
	
			#pragma vertex vert
			#pragma fragment frag
	
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			float4 _SpecularColor;
			float _Gloss;
	
			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				// 这里的tangent之所以是四维的，是因为我们需要使用tangent.w分量来决定切线空间中副切线的方向性
				float4 tangent : TANGENT;
				float2 texcoord : TEXCOORD0;
			};
	
			struct v2f{
				float4 pos : SV_POSITION;
				// 按理说我们现在有两个纹理（纹理和法线纹理），需要有两个uv变量，
				// 但是_MainTex和_BumpMap通常会使用同一组纹理坐标，出于减少插值次数的考虑，
				// 这里可以只用一个uv变量来同时对两个纹理进行采样
				float2 uv : TEXCOORD0;
				float3 tangentLightDir : TEXCOORD1;
				float3 tangentViewDir : TEXCOORD2;
			};
	
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				// 计算切线空间中的视角方向和光线方向
				// 这里的tangent.w分量用来决定副切线的方向性
				float3 bitangent = cross(v.normal, v.tangent.xyz) * v.tangent.w;
				float3x3 rotation = float3x3(v.tangent.xyz, bitangent, v.normal);
				// 计算切线空间中的视角方向和光线方向（先使用内置函数转化到模型空间，再使用TBN逆矩阵转化到切线空间）
				// 使用世界空间的法线、切线和副切线构造了TBN矩阵，这个TBN矩阵的作用是将法线从切线空间转化到世界空间;
				// 同理，使用用模型空间的法线、切线和副切线构造了TBN矩阵，那这个TBN矩阵的作用是将法线从模型空间转化到世界空间。
				// 如果想将法线从世界/模型空间转化到切线空间，就要用到TBN矩阵的逆矩阵，而TBN矩阵是正交矩阵，所以逆矩阵就是转置矩阵。
				// 注意，TBN矩阵的定义是
				// Tx Bx Nx
				// Ty By Ny
				// Tz Bz Nz
				// 上面使用的tangent、bitangent和normal是模型空间的切线、副切线和法线，
				// 计算出的rotation矩阵正好又是转置（逆）矩阵（这也是我们将这个矩阵名字定义为“旋转(rotation)”的原因），
				// 所以这个rotation矩阵的作用是将向量从模型空间转化的切线空间。
				// ObjSpaceLightDir 函数的作用是计算从模型空间中的顶点位置到光源的方向向量，ObjSpaceViewDir同理。
				o.tangentLightDir = normalize( mul(rotation, ObjSpaceLightDir(v.vertex)) );
				o.tangentViewDir = normalize( mul(rotation, ObjSpaceViewDir(v.vertex)) );
				return o;
			}
	
			float4 frag(v2f i) : SV_Target{
				float3 texCol = tex2D(_MainTex, i.uv);
				// 法线纹理中存储的是法线经过映射后得到的像素值（因为法线的分量定义在[-1,1]，而纹理存储的是rgb，范围是[0,1]，
				// 所以在存储法线纹理时，需要将法线的[-1,1]先线性映射到[0,1]后才能存储成一张法线纹理）。所以直接使用tex2D采样
				// 得到的是映射后的法线，需要反映射（unpack）回去，才能得到真正的切线空间的法线。
				float3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				// 下面这里为什么将tangentNormal的xy分量乘以_BumpScale呢？
				// 1、因为法线贴图是2D的，它只存储了xy分量的信息，z分量可以计算出来，不用存储。
				// 2、在大多数3D渲染中，x和y分量对应于屏幕空间的横向和纵向，而z分量对应于深度（即相机视角的前后方向）。
				// 因此，调整x和y分量可以更直观地控制屏幕上可见的凹凸效果，因为它们直接影响到用户在屏幕上看到的形状变化。
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * texCol.rgb;
				float3 diffuse = _LightColor0.rgb * texCol.rgb * max(0, dot(i.tangentLightDir, tangentNormal));
				float3 halfDir = normalize(i.tangentLightDir + i.tangentViewDir);
				float3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				return float4(ambient + diffuse + specular, 1);
			}
			
			ENDCG
		}
	}

	// 在世界空间下进行法线贴图的处理，需要在片元着色器中把法线方向从切线空间变换到世界空间，然后使用光照模型计算光照。
	SubShader {
		Pass{
			Tags{"RenderType" = "Opaque"}
			CGPROGRAM

			#include "Lighting.cginc"

			#pragma vertex vert
			#pragma fragment frag

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			float4 _SpecularColor;
			float _Gloss;

			struct a2v{
				float4 vertex : POSITION;
				// 不要和法线贴图法相混淆了，a2v中的vertex、normal、tangent都模型的顶点、法线和切线，都是在模型空间中定义的。
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldLight : TEXCOORD2;
				float3 worldView : TEXCOORD3;
				float3 t2w0 : TEXCOORD4;
				float3 t2w1 : TEXCOORD5;
				float3 t2w2 : TEXCOORD6;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				
				// 下面这个计算出的就是从切线空间到世界空间的TBN矩阵。
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBitangent = cross(worldNormal, worldTangent) * v.tangent.w;
				o.t2w0 = float3(worldTangent.x, worldBitangent.x, worldNormal.x);
				o.t2w1 = float3(worldTangent.y, worldBitangent.y, worldNormal.y);
				o.t2w2 = float3(worldTangent.z, worldBitangent.z, worldNormal.z);

				o.worldLight = WorldSpaceLightDir(v.vertex);
				o.worldView = WorldSpaceViewDir(v.vertex);
				return o;
			}

			float4 frag(v2f i) : SV_Target {
				fixed3 lightDir = normalize(i.worldLight);
				fixed3 viewDir = normalize(i.worldView);
				// 采样并反映射，得到切线空间下的法线，然后用TBN矩阵将其转化到世界空间。
				fixed3 tangentBumpNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				tangentBumpNormal.xy *= _BumpScale;
				tangentBumpNormal.z = sqrt(1 - saturate(dot(tangentBumpNormal.xy, tangentBumpNormal.xy)));
				fixed3 worldBumpNormal = normalize(mul(float3x3(i.t2w0, i.t2w1, i.t2w2), tangentBumpNormal));
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * tex2D(_MainTex, i.uv).rgb;
				fixed3 diffuse = _LightColor0.rgb * tex2D(_MainTex, i.uv).rgb * max(0, dot(worldBumpNormal, lightDir));
				fixed3 halfDir = normalize(lightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0, dot(worldBumpNormal, halfDir)), _Gloss);
				return float4(ambient + diffuse + specular, 1);
			}
			ENDCG
		}
	}
	FallBack "Specular"
}