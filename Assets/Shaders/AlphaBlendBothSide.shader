Shader "MyShaders/AlphaBlendBothSide"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Alpha ("Alpha", Range(0,1)) = 1
        _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {   
        Tags { "Queue"="Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True"}

		// �޳����棨����Ⱦ���棩
        Pass
        {
			Cull Front
            ZWrite Off
			// ���û�����ӵ�ͬʱҲ�����˻��ģʽ
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Alpha;
            fixed4 _Color;

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

			// Ƭ����ɫ��
			float4 frag(v2f i) : SV_Target {
				float4 texColor = tex2D(_MainTex, i.uv);
				float3 normalDir = normalize(i.worldNormal);
				float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed3 albedo = texColor.rgb * _Color.rgb;
				// ������
				float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				// ������
				float3 diffuse = _LightColor0.rgb * max(0, dot(normalDir, lightDir));

				return float4(ambient + diffuse, texColor.a * _Alpha);
			}

            ENDCG
        }

		// �޳����棨����Ⱦ���棩
		Pass
        {
			Cull Back
            ZWrite Off
			// ���û�����ӵ�ͬʱҲ�����˻��ģʽ
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Alpha;
            fixed4 _Color;

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

			// Ƭ����ɫ��
			float4 frag(v2f i) : SV_Target {
				float4 texColor = tex2D(_MainTex, i.uv);
				float3 normalDir = normalize(i.worldNormal);
				float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed3 albedo = texColor.rgb * _Color.rgb;
				// ������
				float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				// ������
				float3 diffuse = _LightColor0.rgb * max(0, dot(normalDir, lightDir));

				return float4(ambient + diffuse, texColor.a * _Alpha);
			}

            ENDCG
        }
    }

	FallBack "Transparent/VertexLit"
}
