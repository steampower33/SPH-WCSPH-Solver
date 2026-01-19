# Notes / Postmortem — DX12 WCSPH Attempt (Archived)

## Summary
이 저장소에는 WCSPH(EOS-SPH)를 사용한 초기 DX12 compute 기반 유체 시뮬레이션 시도가 포함되어 있습니다.  
작업의 주요 가치는 **GPU 파티클 파이프라인(생성/업데이트/렌더 통합)** 과 **Uniform Grid(Spatial Hash) 기반 neighbor search 파이프라인** 구축 경험에 있습니다.  
다만 일정과 안정화/검증 비용(정확성 테스트, 디버그 지표, 경계 조건, 파라미터 스케일링 등) 제약으로 인해 본 시도는 **아카이브하고 PBF/XPBD 방향으로 피벗**하기로 결정했습니다.

---

## What was implemented
- DX12 Compute 기반 particle pipeline 구축(spawn/update) 및 graphics pipeline 렌더 연동
- 2D 기본 경계 충돌 및 디버그 시각화
- Uniform Grid(Spatial Hash) 기반 neighbor search 파이프라인 구성  
  (hash → grouping → scan/prefix-sum **WIP**)
- Neighbor 결과 기반 밀도/압력(EOS) 계산 및 force 적용 단계 착수
- DX12 compute pass 간 **UAV barrier** 포함한 리소스 동기화 구성
- PIX를 활용한 GPU 데이터 흐름 디버깅

---

## Implementation notes (engineering details)
### 1) Dispatch / 파라미터 스케일(당시 설정)
- Compute group size: `m_groupSizeX = 512`
- `m_smoothingRadius = 0.15`
- `m_radius = 0.075`, `m_dp = 0.075`
- Bounds: `[-3,3]^3`
- Initial particle grid: `nX=50, nY=40, nZ=50` → `numParticles = 100,000`
- Grid dims(추정): `ceil((max*2)/smoothingRadius) = ceil(6/0.15)=40` → 대략 `40^3` 셀 스케일
- Hash table size: `cellCnt = next_prime(numParticles * 1.3)` (약 130k 규모)

> 당시에는 512 dispatch가 적절한지(occupancy/레지스터/메모리 병목 관점) 사전 검증 없이 진행했고, 이후 프로파일링/튜닝 루프가 부족했습니다.

### 2) Neighbor search 구성과 검증 경험
- 해시 기반 그룹화 후 **prefix sum(scan)** 으로 cell range를 만드는 방식으로 설계
- 실제로 **prefix sum 단계에서 잘못 계산된 케이스**를 PIX로 확인한 기억이 있음
- 다만 검증이 “휴리스틱하게(케이스별로 찍어보는 형태)” 진행되어 실수가 재발하기 쉬웠음

### 3) Sorting
- 해시 키/인덱스 정렬에 **bitonic sort**를 사용
- 초기엔 매우 naive한 구현으로 시작 → 더 효율적으로 바꾸려다 실패 → 되돌아가는 과정을 반복
- 다음 구현에서는 **radix sort를 직접 구현**하거나, 더 명확한 GPU sorting 전략으로 재정리 필요

### 4) Data layout (AoS vs SoA)
- 캐시/메모리 접근 패턴을 고려해 **AoS ↔ SoA를 여러 번 변경**
- 당시 체감으로는 현재 구조에서 **SoA가 확실히 성능이 좋았음**

### 5) References used during implementation
- Spatial hashing은 CUDA/NVIDIA 쪽의 오래된 자료(2003~2005년대)를 참고해 구현

---

## Observed issues (symptoms)
### 1) 수치 불안정(특히 저밀도 구간)
- WCSPH pressure force 계산 과정에서 저밀도 구간 수치 불안정이 발생
- 안정화(스케일/정규화, dt 제약, 경계 조건, 파라미터 튜닝)에 예상보다 많은 반복 실험이 필요했음

### 2) 특정 위치/상황에서 파티클이 “사라지는” 문제
- 가장 자주 관측된 현상 중 하나는 특정 위치에 들어가면 파티클이 계속 사라지는 문제였음
- 당시에는 neighbor search(해시/그룹/스캔) 구현 오류 가능성이 높다고 판단했음  
  (prefix sum 버그를 실제로 한 번 확인한 경험도 있어, 정확성 이슈와 연관 가능성이 있음)

### 3) 관측 지표/테스트 하네스 부족
- 레퍼런스(예: Sebastian Lague 접근)를 참고해 구조를 맞춰봤으나,
  수렴/안정성 확보를 위한 **파라미터 튜닝 + 관측 지표(밀도 오차/neighbor count 분포/시간)** 체계가 부족해 목표 품질에 도달하지 못함

---

## Performance notes (bottlenecks)
- 병목은 **neighbor search 자체**와, 그 결과를 반복 사용하는 **밀도/압력 솔버 루프**가 함께 영향을 줌
- 특히 neighbor search가 느리거나/정확성이 흔들리면, 이후 모든 솔버 단계가 함께 악화됨
- 추후에는:
  - neighbor search correctness test(셀 range 검증, count 검증)부터 고정
  - sorting/scan 최적화(또는 radix 기반으로 교체)
  - group size(128/256/512) 비교 프로파일링
  - SoA 유지 + 메모리 접근 패턴/원자 연산 최소화
  등을 우선순위로 둬야 함

---

## Pivot attempts
- 중간에 PBF로 전환을 시도했으나, 기존 파이프라인을 제약 반복 구조로 재구성하는 과정에서
  제한된 일정 내 end-to-end 데모 품질 확보가 어려워 중단했습니다.
- 이후 WCSPH 상태에서 표면 렌더링(표면 재구성/표현) 방향도 검토했으며,
  당시에는 **Screen-space 방식**을 참고(NVIDIA GDC 2010 D3D Effects 자료)하여 접근했습니다.

Reference:
- https://developer.download.nvidia.com/presentations/2010/gdc/Direct3D_Effects.pdf

---

## Key takeaways
- 실시간 유체에서 핵심은 “수식 구현”보다 **정확성 검증(특히 neighbor search), 안정화, 경계 모델, 관측 지표 기반 튜닝 루프**였습니다.
- DX12 compute 기반 데이터 파이프라인(버퍼 설계/디스패치 흐름/PIX 디버깅/UAV barrier)은 이후 프로젝트에도 재사용 가능합니다.
- Sorting/scan, 데이터 레이아웃(SoA)과 같은 “GPU 친화적 구성”이 품질/성능에 직접적으로 연결됩니다.

---

## Next direction
동일한 DX12 compute 기반 구조를 유지하면서, 안정성이 높은 반복 제약 기반 모델(PBF/XPBD 방향)로 재구현합니다.  
다음 구현에서는 아래를 “선행 고정”합니다:
- neighbor search correctness test(셀별 count, range, out-of-bounds 검증) + 디버그 시각화
- sorting/scan 전략 재정리(bitonic 유지 시 최적화, 가능하면 radix sort 도입)
- group size/메모리 레이아웃(SoA) 프로파일링 루프 구축
