Shader "MyShaders/NormalMapTangentSpace"{
	Properties{
		_MainTex("Texture", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Range(0, 10)) = 1
		_SpecularColor("SpecularColor", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(0, 50)) = 30
	}

	// �����߿ռ��½��з�����ͼ�Ĵ������ڶ�����ɫ���н�����ռ���ӽǷ��򡢹��߷���ת�������߿ռ䣬
	// Ȼ����Ƭ����ɫ���в����������߿ռ��еķ��߲�ʹ�ù���ģ�ͼ�����ա�
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
				// �����tangent֮��������ά�ģ�����Ϊ������Ҫʹ��tangent.w�������������߿ռ��и����ߵķ�����
				float4 tangent : TANGENT;
				float2 texcoord : TEXCOORD0;
			};
	
			struct v2f{
				float4 pos : SV_POSITION;
				// ����˵����������������������ͷ�����������Ҫ������uv������
				// ����_MainTex��_BumpMapͨ����ʹ��ͬһ���������꣬���ڼ��ٲ�ֵ�����Ŀ��ǣ�
				// �������ֻ��һ��uv������ͬʱ������������в���
				float2 uv : TEXCOORD0;
				float3 tangentLightDir : TEXCOORD1;
				float3 tangentViewDir : TEXCOORD2;
			};
	
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				// �������߿ռ��е��ӽǷ���͹��߷���
				// �����tangent.w�����������������ߵķ�����
				float3 bitangent = cross(v.normal, v.tangent.xyz) * v.tangent.w;
				float3x3 rotation = float3x3(v.tangent.xyz, bitangent, v.normal);
				// �������߿ռ��е��ӽǷ���͹��߷�����ʹ�����ú���ת����ģ�Ϳռ䣬��ʹ��TBN�����ת�������߿ռ䣩
				// ʹ������ռ�ķ��ߡ����ߺ͸����߹�����TBN�������TBN����������ǽ����ߴ����߿ռ�ת��������ռ�;
				// ͬ��ʹ����ģ�Ϳռ�ķ��ߡ����ߺ͸����߹�����TBN���������TBN����������ǽ����ߴ�ģ�Ϳռ�ת��������ռ䡣
				// ����뽫���ߴ�����/ģ�Ϳռ�ת�������߿ռ䣬��Ҫ�õ�TBN���������󣬶�TBN��������������������������ת�þ���
				// ע�⣬TBN����Ķ�����
				// Tx Bx Nx
				// Ty By Ny
				// Tz Bz Nz
				// ����ʹ�õ�tangent��bitangent��normal��ģ�Ϳռ�����ߡ������ߺͷ��ߣ�
				// �������rotation������������ת�ã��棩������Ҳ�����ǽ�����������ֶ���Ϊ����ת(rotation)����ԭ�򣩣�
				// �������rotation����������ǽ�������ģ�Ϳռ�ת�������߿ռ䡣
				// ObjSpaceLightDir �����������Ǽ����ģ�Ϳռ��еĶ���λ�õ���Դ�ķ���������ObjSpaceViewDirͬ��
				o.tangentLightDir = normalize( mul(rotation, ObjSpaceLightDir(v.vertex)) );
				o.tangentViewDir = normalize( mul(rotation, ObjSpaceViewDir(v.vertex)) );
				return o;
			}
	
			float4 frag(v2f i) : SV_Target{
				float3 texCol = tex2D(_MainTex, i.uv);
				// ���������д洢���Ƿ��߾���ӳ���õ�������ֵ����Ϊ���ߵķ���������[-1,1]��������洢����rgb����Χ��[0,1]��
				// �����ڴ洢��������ʱ����Ҫ�����ߵ�[-1,1]������ӳ�䵽[0,1]����ܴ洢��һ�ŷ�������������ֱ��ʹ��tex2D����
				// �õ�����ӳ���ķ��ߣ���Ҫ��ӳ�䣨unpack����ȥ�����ܵõ����������߿ռ�ķ��ߡ�
				float3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				// ��������Ϊʲô��tangentNormal��xy��������_BumpScale�أ�
				// 1����Ϊ������ͼ��2D�ģ���ֻ�洢��xy��������Ϣ��z�������Լ�����������ô洢��
				// 2���ڴ����3D��Ⱦ�У�x��y������Ӧ����Ļ�ռ�ĺ�������򣬶�z������Ӧ����ȣ�������ӽǵ�ǰ���򣩡�
				// ��ˣ�����x��y�������Ը�ֱ�۵ؿ�����Ļ�Ͽɼ��İ�͹Ч������Ϊ����ֱ��Ӱ�쵽�û�����Ļ�Ͽ�������״�仯��
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

	// ������ռ��½��з�����ͼ�Ĵ�����Ҫ��ƬԪ��ɫ���аѷ��߷�������߿ռ�任������ռ䣬Ȼ��ʹ�ù���ģ�ͼ�����ա�
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
				// ��Ҫ�ͷ�����ͼ��������ˣ�a2v�е�vertex��normal��tangent��ģ�͵Ķ��㡢���ߺ����ߣ�������ģ�Ϳռ��ж���ġ�
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
				
				// �������������ľ��Ǵ����߿ռ䵽����ռ��TBN����
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
				// ��������ӳ�䣬�õ����߿ռ��µķ��ߣ�Ȼ����TBN������ת��������ռ䡣
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