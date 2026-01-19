#include "Common.hlsli"

Texture2D g_texture[50] : register(t0, space0);

PSInput main(VSInput input)
{
    PSInput output;

    float4 normal = float4(input.normalModel, 0.0f);
    output.normalWorld = mul(normal, worldIT).xyz;
    output.normalWorld = normalize(output.normalWorld);

    float4 pos = float4(input.posModel, 1.0f);
    pos = mul(pos, world);

    output.posWorld = pos.xyz;

    pos = mul(pos, view);
    pos = mul(pos, proj);

    output.posProj = pos;
    output.texcoord = input.texcoord;

    return output;
}