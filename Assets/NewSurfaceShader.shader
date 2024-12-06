Shader "Custom/AdvancedWaterShader"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}          // Base texture (Water Surface)
        _NormalMap ("Normal Map", 2D) = "bump" {}           // Normal map for surface distortion
        _ReflectionTex ("Reflection Texture", Cube) = "" {} // Reflection cubemap (Skybox/Environment)
        _WaveSpeed ("Wave Speed", Float) = 0.2              // Speed of waves
        _WaveHeight ("Wave Height", Float) = 0.1            // Height of waves
        _FresnelPower ("Fresnel Power", Float) = 4.0        // Fresnel effect intensity
        _RefractionStrength ("Refraction Strength", Float) = 0.05 // Refraction distortion strength
        _ReflectionIntensity ("Reflection Intensity", Float) = 0.7 // Reflection strength
        _WaveScale ("Wave Scale", Float) = 1.0              // Scale of waves
        _WaterColor ("Water Color", Color) = (0.0, 0.3, 0.6, 1.0) // Base water color
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float3 normal : TEXCOORD3;
            };

            // Uniforms
            uniform float _WaveSpeed;
            uniform float _WaveHeight;
            uniform float _FresnelPower;
            uniform float _RefractionStrength;
            uniform float _ReflectionIntensity;
            uniform float _WaveScale;
            uniform float4 _WaterColor;
            sampler2D _MainTex;
            sampler2D _NormalMap;
            samplerCUBE _ReflectionTex;
            uniform float4 unity_CameraPosition;

            v2f vert(appdata v)
            {
                v2f o;

                // Apply wave displacement
                float waveOffset = sin(v.vertex.x * _WaveScale + _Time.y * _WaveSpeed) * _WaveHeight;
                waveOffset += cos(v.vertex.z * _WaveScale + _Time.y * _WaveSpeed * 0.5) * _WaveHeight;
                v.vertex.y += waveOffset;

                // Transform vertex position and normal to world space
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));

                // Calculate view direction (camera to vertex)
                o.viewDir = normalize(unity_CameraPosition.xyz - o.worldPos);
                o.uv = v.uv;

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // Base water color
                float4 baseColor = tex2D(_MainTex, i.uv) * _WaterColor;

                // Normal distortion
                float3 normalDistortion = UnpackNormal(tex2D(_NormalMap, i.uv));
                normalDistortion = normalize(normalDistortion * 2.0 - 1.0);

                // Combine with surface normal
                float3 distortedNormal = normalize(i.normal + normalDistortion * _RefractionStrength);

                // Fresnel effect
                float fresnel = pow(1.0 - dot(i.viewDir, i.normal), _FresnelPower);

                // Reflection
                float3 reflectionDir = reflect(i.viewDir, distortedNormal);
                float4 reflection = texCUBE(_ReflectionTex, reflectionDir);

                // Final color with Fresnel blending
                float4 finalColor = lerp(baseColor, reflection, fresnel * _ReflectionIntensity);
                finalColor.a = fresnel * 0.5 + 0.3; // Add transparency based on Fresnel

                return finalColor;
            }
            ENDCG
        }
    }

    FallBack "Transparent/Diffuse"
}
