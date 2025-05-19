#include "Common.hlsli"

Texture2D texture[100] : register(t0, space0);
TextureCube skyboxTexture[10] : register(t100, space0);

static const uint textureSizeOffset = 100;

float4 main(PSInput input) : SV_TARGET
{
	float3 baseColor = float3(1,1,1);

	float3 V = normalize(-input.posWorld);
	float3 R = reflect(V, normalize(input.normalWorld));
	float  F = pow(1.0 - saturate(dot(input.normalWorld, V)), 5);
	float3 refl = skyboxTexture[cubemapSpecularIndex - textureSizeOffset].SampleLevel(linearWrapSampler, input.normalWorld, 0.0).rgb;

	return float4(lerp(baseColor, refl, F), 0.5);
}