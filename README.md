# DX12 WCSPH (EOS-SPH) Attempt — Archived

DirectX 12 **Compute Shader** 기반으로 WCSPH(EOS-SPH) 유체 시뮬레이션을 시도했던 저장소입니다.  
현재는 **아카이브 상태**이며, 동일한 DX12 compute 기반 파이프라인을 유지한 채 **PBF/XPBD 방향으로 재구현**을 계획하고 있습니다.

<video src="./Docs/demo1.mp4" controls muted loop playsinline width="720"></video>

> 자세한 회고/의사결정 기록: [POSTMORTEM.md](./Docs/POSTMORTEM.md)

---

## What’s inside (implemented / WIP)
- DX12 Compute 기반 particle pipeline 구축(spawn/update) 및 graphics pipeline 렌더 연동
- 2D 기본 경계 충돌 + 디버그 시각화
- Uniform Grid(Spatial Hash) 기반 neighbor search 파이프라인 구성  
  (hash → grouping → scan/prefix-sum **WIP**)
- Neighbor 결과 기반 밀도/압력(EOS) 계산 및 force 적용 단계 착수

---

## Requirements
- Windows 10+ (DirectX 12)
- Visual Studio 2019
- C++17
- vcpkg
- Windows SDK 10.0.18362.0+ (HLSL 2021)

---

## Build & Run (Quick Start)

### 1) Install vcpkg
```sh
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
bootstrap-vcpkg.bat
vcpkg integrate install
```

### 2) Enable vcpkg manifest mode (Visual Studio)

Project -> Properties -> vcpkg -> Use Vcpkg Manifest = Yes

vcpkg.json(Manifest mode) 기준으로 의존성이 자동 설치/연동됩니다.

### 3) Build & Run

솔루션 열기 → x64 / Debug(or Release) → 실행

---

## Assets / Third-Party Content

This repository uses an HDRI environment map originally from ambientCG:
- Asset: IndoorEnvironmentHDRI013 (converted to cubemap for this project)
- Source: https://ambientcg.com/a/IndoorEnvironmentHDRI013
- License: Creative Commons CC0 1.0 Universal

Attribution is not required for CC0, but appreciated.

Suggested credit line (optional):

> Created using IndoorEnvironmentHDRI013 from ambientCG.com, licensed under CC0 1.0 Universal.

---

## Debug shader PDB
- Debug 빌드에서 shader PDB가 ./PDB/ 아래에 생성됩니다.
- PDB/ 폴더는 런타임에 자동 생성되도록 구성하는 것을 권장합니다(커밋 대상 아님).

---

## Repo notes
- Fluid 관련 주요 코드:
    - Core/SphSimulator.cpp
    - Shaders/SphCS.hlsl

--- 

## Controls
- `Space` : Start / Pause simulation
- `F` : Toggle camera lock
- `T` : Toggle particle init mode (Dam Break / Emitter)
- `R` : Reset particle positions
- `W/A/S/D` : Move camera

---

## License
- Code: MIT License (see LICENSE)
- Third-party assets: 각 에셋의 라이선스를 따릅니다(ambientCG HDRI는 CC0 1.0).

---

## Technical notes (high-level)
- GPU neighbor search: spatial hashing + grouping + prefix-sum(cell ranges) (WIP)
- Sorting: bitonic sort (naive → attempted optimization → reverted)
- Data layout: switched AoS/SoA multiple times; SoA performed better in this pipeline
- Debugging: PIX-based GPU buffer validation + UAV barriers between compute passes
- Scale (at the time): ~100k particles (50×40×50), group size 512