# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Patal(팥알) 입력기는 macOS용 한글 입력기로, InputMethodKit 기반의 입력 소스 플러그인이다. Swift로 구현되었으며 세벌식 자판(공세벌 P3, 신세벌 P2, 신세벌 PCS)을 지원한다.

## 빌드 및 개발 명령어

```bash
make build         # Release 빌드
make debug         # Debug 빌드 (로깅 활성화)
make test          # 테스트 실행 (xcbeautify 포맷)
make format        # swift-format 코드 정렬
make install       # 개발자용 로컬 설치 (/Library/Input Methods/Patal.app)
make package       # .pkg 패키지 생성
make distribute    # 서명 포함 배포 패키지 생성
make log           # 실시간 로그 모니터링
make perf-log      # 성능 로그 모니터링
make clean         # dist 정리
```

단일 테스트 실행:
```bash
xcodebuild test -project macOS/Patal.xcodeproj -scheme Patal -only-testing:PatalTests/TestClassName/testMethodName
```

## 아키텍처

### 입력 처리 파이프라인

물리적 키 입력부터 한글 출력까지의 흐름:

```
KeyEvent → InputController → KeyCodeMapper → HangulProcessor → CompositionStateMachine → HangulComposer → 출력
```

1. **InputController** (`InputController.swift`, `PatalInputController.swift`): IMKInputController 서브클래스. 클라이언트별 인스턴스 관리, `inputText(_:key:modifiers:client:)`에서 입력 처리
2. **KeyCodeMapper** (`KeyCodeMapper.swift`): 물리적 키코드 → 한글 문자 변환. QWERTY/Colemak/Dvorak 독립적으로 물리적 키코드 기반 동작
3. **HangulProcessor** (`HangulProcessor.swift`): CommitState/InputStrategy 관리, 백스페이스 처리 전략, preedit 상태 조정
4. **CompositionStateMachine** (`StateMachine/CompositionStateMachine.swift`): 한글 자소 조합의 상태 전이 엔진. InputEvent(chosung/jungsung/jongsung)를 받아 TransitionResult(invalid/composing/complete)를 반환
5. **HangulComposer** (`HangulComposer.swift`): 초성/중성/종성을 유니코드 오프셋(U+AC00 기준)으로 조합하여 완성 한글 생성

### 자판 레이아웃 시스템

`HangulAutomata` 프로토콜을 구현하는 3개의 자판:
- **Han3P3Layout**: 공세벌 P3 자판
- **Han3ShinP2Layout**: 신세벌 P2 자판 (첫/가/끝 갈마들이)
- **Han3ShinPcsLayout**: 신세벌 PCS (50% 이하 키보드용 커스텀)

`LayoutTrait`으로 자판별 동작 차이 제어: `모아주기`, `아래아`, `수정기호`, `두줄숫자`, `글자단위삭제`

### 핵심 데이터 타입

- `HangulCode.swift`: 초성/중성/종성/자음/모음 enum 정의
- `InputEvent`: 자소 이벤트 (chosung, jungsung, jongsung)
- `TransitionResult`: 상태 전이 결과 (invalid, composing, complete)
- `SyllableBuffer`: 조합 중인 자소 버퍼 및 키 히스토리

## 소스 코드 위치

- 메인 소스: `macOS/Patal/`
- 상태머신: `macOS/Patal/StateMachine/`
- 자판 레이아웃: `macOS/Patal/Layouts/`
- 테스트: `macOS/PatalTests/`
- 빌드 스크립트: `script/`
- 개발 문서: `misc/`

## 코딩 컨벤션

- swift-format 설정: 라인 120자, 들여쓰기 4칸 (`.swift-format.json` 참조)
- 성능 핫패스에 `@_optimize(speed)`, `@inline(__always)` 적용
- Swift 6 Sendable 및 async 지원
- 한글 도메인 용어를 코드에 직접 사용 (초성, 중성, 종성, 자음, 모음 등)
- Bundle ID: `com.soomtong.inputmethod.Patal`

## 커밋 규칙

- 대문자로 시작, 80자 이하, 접두어 없음
