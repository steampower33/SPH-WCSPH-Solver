#include "SphCommon.hlsli"

StructuredBuffer<float3> PredictedPositions : register(t1);
StructuredBuffer<uint> CellStart : register(t9);
StructuredBuffer<uint> CellCount : register(t7);
StructuredBuffer<uint2> CellOffset : register(t8);
StructuredBuffer<uint> SortedIdx : register(t11);
StructuredBuffer<float> spawnTimes : register(t6);
StructuredBuffer<float3> SortedPositions : register(t13);

RWStructuredBuffer<float> Densities : register(u4);
RWStructuredBuffer<Sorted> SortedInfo : register(u12);

[numthreads(GROUP_SIZE_X, 1, 1)]
void main(uint tid : SV_GroupThreadID,
	uint3 gtid : SV_DispatchThreadID,
	uint groupIdx : SV_GroupID)
{
	uint index = groupIdx.x * GROUP_SIZE_X + tid;
	if (index >= numParticles) return;

	if (currentTime < spawnTimes[index]) return;

	float3 pos_pred_i = PredictedPositions[index];

	int3 cellID = floor((pos_pred_i - minBounds) / smoothingRadius);

	float density = 0.0;
	float nearDensity = 0.0;
	float sqrRadius = smoothingRadius * smoothingRadius;
	for (int i = 0; i < 27; ++i)
	{
		int3 neighborIndex = cellID + offsets3D[i];

		uint flatNeighborIndex = GetCellKeyFromCellID(neighborIndex);

		uint startIndex = CellStart[flatNeighborIndex];
		uint endIndex = startIndex + CellCount[flatNeighborIndex];

		if (startIndex == endIndex) continue;

		for (int n = startIndex; n < endIndex; ++n)
		{
			uint j = SortedIdx[n];

			float3 pos_pred_j = SortedPositions[n];

			float3 x_ij_pred = pos_pred_j - pos_pred_i;

			float sqrDist = dot(x_ij_pred, x_ij_pred);

			if (sqrDist > sqrRadius) continue;

			float r = sqrt(sqrDist);
			density += mass * DensityKernel(r, smoothingRadius);
		}
	}
	uint2 info = CellOffset[index];
	if (info.x == 0xFFFFFFFF || info.y == 0xFFFFFFFF)
		return;
	uint dst = CellStart[info.x] + info.y;

	density = max(density, 1e-6f);
	SortedInfo[dst].density = density;
	SortedInfo[dst].pressure = PressureFromDensity(density, density0, pressureCoeff);
	Densities[index] = max(density, 1e-6f);
}