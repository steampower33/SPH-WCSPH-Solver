#include "Common.hlsli"

Texture2D g_texture[] : register(t0, space1);

struct SamplingPSInput
{
    float4 posModel : SV_POSITION;
    float2 texcoord : TEXCOORD;
};

float4 main(SamplingPSInput input) : SV_TARGET
{
    float x = input.texcoord.x;
    float y = input.texcoord.y;
    
    float3 a = g_texture[index].Sample(linearClampSampler, float2(x - 2 * pixelStepX, y + 2 * pixelStepY)).rgb;
    float3 b = g_texture[index].Sample(linearClampSampler, float2(x, y + 2 * pixelStepY)).rgb;
    float3 c = g_texture[index].Sample(linearClampSampler, float2(x + 2 * pixelStepX, y + 2 * pixelStepY)).rgb;
    
    float3 d = g_texture[index].Sample(linearClampSampler, float2(x - 2 * pixelStepX, y)).rgb;
    float3 e = g_texture[index].Sample(linearClampSampler, float2(x, y)).rgb;
    float3 f = g_texture[index].Sample(linearClampSampler, float2(x + 2 * pixelStepX, y)).rgb;
    
    float3 g = g_texture[index].Sample(linearClampSampler, float2(x - 2 * pixelStepX, y - 2 * pixelStepY)).rgb;
    float3 h = g_texture[index].Sample(linearClampSampler, float2(x, y - 2 * pixelStepY)).rgb;
    float3 i = g_texture[index].Sample(linearClampSampler, float2(x + 2 * pixelStepX, y - 2 * pixelStepY)).rgb;
    
    float3 j = g_texture[index].Sample(linearClampSampler, float2(x - pixelStepX, y + pixelStepY)).rgb;
    float3 k = g_texture[index].Sample(linearClampSampler, float2(x + pixelStepX, y + pixelStepY)).rgb;
    float3 l = g_texture[index].Sample(linearClampSampler, float2(x - pixelStepX, y - pixelStepY)).rgb;
    float3 m = g_texture[index].Sample(linearClampSampler, float2(x + pixelStepX, y - pixelStepY)).rgb;
    
    float3 color = e * 0.125;
    color += (a + c + g + i) * 0.03125;
    color += (b + d + f + h) * 0.0625;
    color += (j + k + l + m) * 0.125;
    
    return float4(color, 1.0);
}