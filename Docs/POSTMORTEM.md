
# Notes / Postmortem — DX12 WCSPH Attempt (Archived)

## Summary
이 저장소에는 WCSPH(EOS-SPH)를 사용한 초기 DX12 compute 기반 유체 시뮬레이션 시도가 포함되어 있습니다.  
이 작업의 주요 가치는 **GPU 파티클 파이프라인(생성/업데이트/렌더링 통합)** 과 **Uniform Grid 기반 neighbor search 파이프라인** 입니다.  
다만 일정과 안정성/반복 실험 비용(튜닝/디버그 지표/경계 조건 등) 제약으로 인해, 본 시도는 **아카이브(중단)하고 PBF/XPBD 방향으로 피벗**하기로 결정했습니다.

## What was implemented
- DX12 Compute 기반 particle pipeline 구축 (spawn/update) 및 graphics pipeline 렌더 연동
- 2D 기본 경계 충돌 및 디버그 시각화
- Uniform Grid(Spatial Hash) 기반 neighbor search 파이프라인 구성 (hash → grouping → scan/prefix-sum WIP)
- Neighbor 결과를 기반으로 밀도/압력(EOS) 계산 및 force 적용 단계 착수

## Observed issues
- WCSPH 기반 pressure force 계산 과정에서 **저밀도 구간 수치 불안정**이 발생했고,
  안정화(스케일/정규화, dt 제약, 경계 조건 등)에 예상보다 많은 반복 실험이 필요했습니다.
- 레퍼런스 구현(예: Sebastian Lague 방식)을 참고하여 구조를 맞춰보았으나,
  수렴/안정성 확보를 위한 **파라미터 튜닝 및 관측 지표 체계**가 부족해 목표 품질에 도달하지 못했습니다.

## Pivot attempts
- 중간에 PBF로 전환을 시도했으나,
  기존 파이프라인(이웃 탐색/충돌/업데이트 루프)을 제약 반복 구조로 재구성하는 과정에서
  제한된 일정 내에 end-to-end 데모 품질을 확보하기 어려워 중단했습니다.
- 이후 WCSPH 상태에서 표면 렌더링(표면 재구성/표현) 방향도 검토했으나,
  우선순위를 “안정적 시뮬레이션 코어 + 관측 지표 기반 튜닝 루프”로 재설정하기 위해 아카이브했습니다.

## Key takeaways
- 실시간 유체에서 핵심은 “수식 구현”보다 “안정화(스케일/정규화), 경계 모델, 관측 지표(밀도 오차/neighbor count/시간)”였습니다.
- DX12 compute 기반 데이터 파이프라인(버퍼 설계/디스패치 흐름/디버깅)은 이후 프로젝트에도 재사용 가능합니다.

## Next direction
- 동일한 DX12 compute 기반 구조를 유지하면서, 안정성이 높은 반복 제약 기반 모델(PBF/XPBD 방향)로 재구현합니다.
