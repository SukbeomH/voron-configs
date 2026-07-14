# Eddy Tap Z 기준점 변동 및 direct mesh 중복 보정 사고 기록

작성일: 2026-07-14
대상 호스트: `voronrpi4b` / `192.168.0.29`
대상 Klipper: `v0.13.0-699-gc707dd19` (`c707dd19`)
심각도: 높음 — 첫 레이어 베드 긁힘 또는 공중 출력 가능

## 현재 결론

이번 문제의 주원인은 Eddy Tap 반복성이나 툴헤드 기계 고장이 아니라 다음 설정과 Klipper 구현의 조합이다.

```ini
[bed_mesh]
zero_reference_position: 125, 100
mesh_pps: 0,0
```

`mesh_pps: 0,0`에서는 Klipper가 메시 알고리즘을 `direct`로 강제한다. 이 경로에서 `probed_matrix`와 `mesh_matrix`가 같은 리스트 객체를 참조하지만 `set_zero_reference()`는 두 행렬을 각각 보정한다. 결과적으로 같은 행렬에서 `zero_reference_position` 오프셋이 두 번 빠진다.

확인한 코드 경로:

1. `_verify_algorithm()`이 `mesh_pps` 두 값이 0이면 알고리즘을 `direct`로 바꾼다.
2. `build_mesh()`가 `self.probed_matrix = z_matrix`를 설정한다.
3. `_sample_direct()`가 `self.mesh_matrix = z_matrix`를 설정한다.
4. 두 속성이 같은 객체를 가리키게 된다.
5. `set_zero_reference()`가 `[self.probed_matrix, self.mesh_matrix]`를 순회하면서 동일 기준값을 두 번 뺀다.

2026-07-14 확인 시 공식 Klipper master에도 동일한 객체 공유 구조가 있었다.

- <https://github.com/Klipper3d/klipper/blob/master/klippy/extras/bed_mesh.py>
- <https://github.com/Klipper3d/klipper/blob/master/docs/Bed_Mesh.md#configuring-the-zero-reference-position>

이는 현재 소스와 실측값을 결합한 원인 판정이다. 공식 이슈에서 수정 완료됐다고 확인한 내용은 아니다.

## 사용자에게 보였던 증상

1. 출력마다 첫 레이어 Z 조정 방향이 달라 보였다.
2. 어떤 출력에서는 `+0.69~+0.75mm`를 올려야 했고 다른 출력에서는 반대로 약 `-0.70~-0.85mm`를 내려야 했다.
3. 라이브 Z 조정을 저장해도 다음 출력에서 같은 물리 높이가 재현되지 않는 것처럼 보였다.
4. `tap_threshold`를 재교정해도 증상이 해결되지 않았다.
5. 첫 레이어가 베드를 긁거나, 반대로 필라멘트가 붙지 않고 끌려다녔다.

## 결정적 실측 증거

수정 전 실패 출력:

- 저장 `tap_z_offset`: `-0.740mm`
- `zero_reference_position`: `(125,100)`
- Klipper 로그의 기준값: `-0.694252mm`
- 생성 메시 범위: `+0.579624~+0.724837mm`
- 생성 메시를 `(125,100)`에서 직접 보간한 값: `+0.694251912mm`
- 로그 기준값과 잔류 메시값 차이: 약 `0.00000009mm`
- 사용자가 첫 레이어에서 내린 값: 최대 `-0.85mm`

즉 기준점에서 0이어야 할 메시가 `+0.694252mm`를 다시 더했고, 사용자의 큰 음수 조정 대부분이 이 상수 오류를 상쇄했다.

수정 전 메시 예:

```text
zero reference calculation: -0.694252
runtime mesh at zero reference: +0.694251912
runtime mesh range: +0.579624 .. +0.724837
```

## 제외한 원인

### Eddy Tap 반복성

동일 조건의 Tap 반복 범위는 대체로 약 `0.013~0.033mm`였다. 한 번의 Tap 세트 내부 반복성으로는 `0.7~0.8mm` 변동을 설명할 수 없다.

### QGL 및 Z 좌표 복원

- QGL 최종 편차는 허용 범위 안이었다.
- `SET_KINEMATIC_POSITION` 전후 좌표를 기록해 예상한 Tap 결과만큼만 바뀌는 것을 확인했다.
- `SAVE_GCODE_STATE`와 `RESTORE_GCODE_STATE` 전후 스테퍼, 기구 좌표, G-code Z는 동일했다.

### adaptive mesh 기준 좌표

`zero_reference_position: 125,100`과 Tap 기준점은 같은 물리적 베드 좌표를 사용한다. Eddy의 `y_offset: 30`은 scan 시 툴헤드 이동 위치에 반영되며, 이번 상수 오류의 직접 원인이 아니었다.

### Obico

Obico 제거 여부는 이번 메시 행렬 계산과 무관했다.

### 툴헤드

현재 Tap 반복성, QGL 결과, 수정 후 메시 및 첫 레이어 재현성을 보면 툴헤드 교체 근거가 없다.

## 적용한 수정

현재 `printer.cfg`의 `[bed_mesh]`:

```ini
[bed_mesh]
speed: 350
horizontal_move_z: 2
mesh_min: 15, 35
mesh_max: 230, 220
zero_reference_position: 125, 100
probe_count: 30, 30
adaptive_margin: 10
# Keep probed_matrix and mesh_matrix separate so zero_reference_position
# is applied once per matrix instead of twice in Klipper's direct mode.
mesh_pps: 1,1
algorithm: bicubic
move_check_distance: 3.0
```

`mesh_pps: 1,1`과 `algorithm: bicubic`을 사용하면 보간 메시가 별도 행렬로 생성된다. `set_zero_reference()`가 `probed_matrix`와 `mesh_matrix`에 각각 한 번씩 보정하므로 동일 객체 이중 보정이 발생하지 않는다.

Klipper 소스는 직접 패치하지 않았다. 소스 패치는 업데이트 시 사라질 수 있으므로 설정 우회를 canonical 해결책으로 선택했다.

## 수정 후 검증

### 무압출 전체 rapid scan

- 메시 크기: `59x59`
- 메시 범위: `-0.145530~+0.111179mm`
- `(125,100)` 보간값: `-0.000000115mm`
- 명령 Z: `0.250000mm`
- 툴헤드 Z: `0.250000mm`
- 기구 계산 Z: `0.250310mm`

### 실제 adaptive mesh 재출력

- 메시 크기: `33x25`
- 메시 범위: `-0.142222~+0.037869mm`
- `(125,100)` 보간값: `+0.000000152mm`
- 이전의 약 `+0.694mm` 상수 오차 재발 없음

### 실제 첫 레이어

- 테스트 파일: `First_Layer_Patch-0.25mm (1)_T0_ABS_5m48s.gcode`
- 출력 완료: 정상
- 첫 패치: 일부 라인 간격 확인
- 이후 다섯 패치: 연속된 면으로 출력
- 최종 라이브 조정: `-0.07mm`
- 1차 검증에서 `Z_OFFSET_APPLY_PROBE METHOD=tap` 적용 후 `tap_z_offset`: `-0.670mm`

## 현재 canonical 값

```ini
[probe_eddy_current btt_eddy]
tap_threshold: 1328.851
tap_z_offset: -0.540
```

```ini
[bed_mesh]
zero_reference_position: 125, 100
mesh_pps: 1,1
algorithm: bicubic
```

`tap_z_offset`은 `SAVE_CONFIG` 자동 생성 블록에 저장돼 있다. 첫 레이어 라이브 조정의 부호와 저장값 변화 방향은 반대로 보일 수 있으므로 숫자를 직접 추측해 수정하지 않는다.

Tap 오프셋 저장은 반드시 다음처럼 방법을 명시한다.

```gcode
Z_OFFSET_APPLY_PROBE METHOD=tap
SAVE_CONFIG
```

일반 `Z_OFFSET_APPLY_PROBE`는 scan/default 거리 보정 경로를 바꿀 수 있으므로 Tap 첫 레이어 보정 저장에 사용하지 않는다.

- <https://github.com/Klipper3d/klipper/blob/master/docs/G-Codes.md#z_offset_apply_probe>
- <https://github.com/Klipper3d/klipper/blob/master/docs/Eddy_Probe.md>

## 정상 운영 절차

1. 베드의 이전 출력물과 접착제를 정리한다.
2. 노즐 끝의 잔여 필라멘트를 제거한다.
3. 실제 출력과 같은 베드 및 Tap 온도를 사용한다.
4. `PRINT_START`에서 QGL, 노즐 청소, Tap 기준 설정, rapid scan 순서를 유지한다.
5. 첫 레이어는 `0.01mm` 단위로 조정한다.
6. 정상적으로 붙은 패치에서 확정한 값만 저장한다.
7. 저장 후 재시작하고 다음 출력의 런타임 오프셋이 0에서 시작하는지 확인한다.

## 빠른 이상 판정

다음 조건이면 출력을 중단하고 메시 기준값부터 확인한다.

1. adaptive mesh 전체가 같은 부호로 `0.3mm` 이상 치우친다.
2. `zero_reference_position`에서 계산한 메시값이 약 `+/-0.02mm`를 넘는다.
3. 첫 레이어에 `+/-0.2mm` 이상의 라이브 조정이 다시 필요하다.
4. 이전 출력과 반대 방향으로 큰 조정이 필요하다.

큰 오차가 생겼을 때 `tap_threshold`부터 재교정하지 않는다. 먼저 다음을 확인한다.

```text
active mesh range
mesh value at X125 Y100
runtime homing_origin.z
active tap_z_offset
PRINT_START가 SET_GCODE_OFFSET Z=0으로 시작했는지
```

## Klipper 업데이트 후 확인

Klipper 업데이트 뒤 다음 소스 부분을 확인한다.

```python
def _sample_direct(self, z_matrix):
    self.mesh_matrix = z_matrix
```

그리고 다음 로직을 확인한다.

```python
for matrix in [self.probed_matrix, self.mesh_matrix]:
    # zero reference subtraction
```

direct 모드에서 두 행렬이 더 이상 같은 객체가 아니거나, 중복 객체를 한 번만 처리하도록 수정됐다면 upstream 수정 가능성이 있다. 그래도 바로 `mesh_pps: 0,0`으로 복귀하지 말고 다음 순서로 검증한다.

1. 설정 백업
2. 무압출 Tap 기준 설정
3. 전체 rapid scan
4. `(125,100)` 메시값이 0인지 계산
5. 작은 첫 레이어 패치 출력

이 검증 전에는 현재 `mesh_pps: 1,1`, `algorithm: bicubic`을 유지한다.

## 툴헤드 교체 판단 기준

다음이 반복될 때만 툴헤드 또는 Eddy 장착부 교체를 검토한다.

1. 같은 온도와 같은 위치에서 Tap 반복 범위가 계속 `0.05~0.10mm` 이상이다.
2. 노즐 청소 후에도 접촉점이 무작위로 크게 변한다.
3. Eddy amplitude 경고와 실제 Tap 실패 또는 충돌이 함께 반복된다.
4. 노즐, 히트브레이크, 캐리지 또는 센서 장착부 유격이 물리적으로 확인된다.

툴헤드를 교체하면 다음을 모두 다시 수행한다.

1. Eddy drive current 캘리브레이션
2. Eddy 거리 캘리브레이션
3. `x_offset`, `y_offset` 측정
4. Tap threshold guess/refine/verify
5. Tap Z offset 첫 레이어 검증
6. QGL 및 전체/adaptive mesh 기준점 검증

## 백업 및 롤백

메시 설정 수정 전:

```text
/home/sukbeom/printer_data/config/backups/codex-bed-mesh-direct-fix-20260714-181030/printer.cfg
```

최종 Tap 오프셋 저장 전:

```text
/home/sukbeom/printer_data/config/backups/codex-final-tap-offset-20260714-205356/printer.cfg
```

롤백은 전체 파일을 무조건 덮어쓰기보다 현재 설정과 diff를 확인하고 `[bed_mesh]` 및 자동 저장 블록의 `tap_z_offset`만 선별 복원한다.

## 후속 첫 레이어 확정 및 브러시 좌표 수정

2026-07-14 후속 출력에서 다음 adaptive mesh를 확인했다.

- 영역: `X34.4683~204.4383`, `Y49.9767~219.8067`
- 실측/보간 크기: `24x28` / `47x55`
- 메시 범위: `-0.162982~+0.035010mm`
- 전체 편차: `0.197992mm`
- `(125,100)` 보간값: `-0.000000142mm`

첫 레이어에서 런타임 Z 오프셋 `-0.130mm`를 정상값으로 확정했다. 출력 취소 후 다음 순서로 영구 반영했다.

```gcode
Z_OFFSET_APPLY_PROBE METHOD=tap
SAVE_CONFIG
```

저장 대기 항목은 `tap_z_offset: -0.540` 하나뿐이었으며, 재시작 후 해당 값과 런타임 Z 오프셋 `0.000mm`를 확인했다.

같은 출력에서 노즐 와이핑 경로가 실제 후방 브러시보다 뒤쪽으로 이동하는 회귀도 확인했다. 작업본이 커밋된 좌표보다 Y 방향으로 `+1.0mm` 이동해 있었으므로 다음처럼 복원했다.

```ini
variable_brush_y: 251.5
variable_brush_y_min: 251.0
variable_brush_y_max: 252.0
variable_safe_y_min: 251.0
variable_safe_y_max: 253.0
```

재시작 후 활성 매크로 값이 `Y251~252`인지 확인하고 `CLEAN_NOZZLE`을 실행했다. 청소는 브러시 위 `Y251~252`, `Z-0.5`에서 수행됐으며 `X149 Y252 Z20`으로 상승해 정상 완료됐다.

후속 변경 전 백업:

```text
/home/sukbeom/printer_data/config/backups/codex-nozzle-brush-y-fix-20260714-210420/macros.cfg
/home/sukbeom/printer_data/config/backups/codex-confirm-tap-offset-20260714-211338/printer.cfg
```

## 최종 상태

2026-07-14 최종 확인:

- Klipper: ready
- 설정 경고: 없음
- 저장 대기 항목: 없음
- 런타임 Z 오프셋: `0.000mm`
- 활성 메시: 없음
- 히터 목표: 0
- `tap_threshold`: `1328.851`
- `tap_z_offset`: `-0.540mm`
- `mesh_pps`: `1,1`
- `algorithm`: `bicubic`
