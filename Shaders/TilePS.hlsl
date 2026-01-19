#include "Common.hlsli"

float4 main(PSInput input) : SV_TARGET
{
    float2 uv = input.texcoord;

    float2 t = uv * 2;

    float2 f = floor(t);

    float checker = fmod(f.x + f.y, 2.0);

    return float4(checker, checker, checker, 1);
}