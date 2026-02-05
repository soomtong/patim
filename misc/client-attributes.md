# macOS 애플리케이션별 validAttributesForMarkedText 측정 결과

> 이 문서는 Patal 입력기의 InputStrategy 결정에 사용되는 실제 측정값을 기록합니다.

## 📋 측정 환경

- **macOS 버전**: macOS 15.7.2 (Sequoia)
- **Patal 버전**: 103b623 (2026-02-05)
- **측정 날짜**: 2026-02-05
- **측정 방법**: Debug 빌드 + `make log` 실시간 모니터링

## 📊 측정 결과 요약

| 카테고리 | directInsert | swapMarked | 빈 배열 | 합계 |
|---------|--------------|------------|---------|------|
| 브라우저 (3개) | 1 | 2 | 0 | 3 |
| 개발 도구 (3개) | 1 | 2 | 0 | 3 |
| 텍스트 편집 (3개) | 3 | 0 | 0 | 3 |
| Electron (3개) | 0 | 3 | 0 | 3 |
| **합계 (12개)** | **5** | **7** | **0** | **12** |

> **측정 상태**: ✅ 측정 완료 (2026-02-05 22:16)

## 🌐 브라우저

### Safari (com.apple.Safari)
- **Attributes**: `["NSFont", "NSUnderline", "NSColor", "NSBackgroundColor", "NSUnderlineColor", "NSMarkedClauseSegment", "NSLanguage", "NSTextInputReplacementRangeAttributeName", "NSTextAlternatives", "NSTextInsertionUndoable", "NSDictationHiliteMarkedText"]`
- **전략**: `directInsert`
- **테스트 위치**: 주소창
- **비고**: NSTextAlternatives 포함, 11개 속성 

### Chrome (com.google.Chrome)
- **Attributes**: `["NSMarkedClauseSegment"]`
- **전략**: `swapMarked`
- **테스트 위치**: 주소창
- **비고**: 이미 테스트 코드 존재 (InputStrategyTests.swift:98-103)

### Firefox (org.mozilla.firefox)
- **Attributes**: `["NSUnderline", "NSUnderlineColor", "NSMarkedClauseSegment", "NSTextInputReplacementRangeAttributeName", "NSDictationHiliteMarkedText"]`
- **전략**: `swapMarked`
- **테스트 위치**: 주소창
- **비고**: VS Code, Slack, Discord와 동일한 속성 세트 

## 🛠️ 개발 도구

### Xcode (com.apple.dt.Xcode)
- **Attributes**: `["NSMarkedClauseSegment", "NSGlyphInfo", "NSDictationHiliteMarkedText"]`
- **전략**: `directInsert`
- **테스트 위치**: 소스 코드 편집기
- **비고**: NSMarkedClauseSegment + NSGlyphInfo 조합으로 directInsert

### Terminal.app (com.apple.Terminal)
- **Attributes**: `["NSUnderline", "NSBackgroundColor", "NSDictationHiliteMarkedText"]`
- **전략**: `swapMarked`
- **테스트 위치**: 명령줄 프롬프트
- **비고**: 빈 배열 예상했으나 3개 속성 있음

### iTerm2 (com.googlecode.iterm2)
- **Attributes**: `["NSColor", "NSBackgroundColor", "NSUnderline", "NSFont", "NSDictationHiliteMarkedText"]`
- **전략**: `swapMarked`
- **테스트 위치**: 명령줄 프롬프트
- **비고**: Terminal.app보다 풍부 (5개 vs 3개), NSFont 포함 

## 📝 텍스트 편집기

### TextEdit (com.apple.TextEdit)
- **Attributes**: `["NSFont", "NSUnderline", "NSColor", "NSBackgroundColor", "NSUnderlineColor", "NSMarkedClauseSegment", "NSLanguage", "NSTextInputReplacementRangeAttributeName", "NSGlyphInfo", "NSTextAlternatives", "NSTextInsertionUndoable", "NSAttachment", "NSDictationHiliteMarkedText"]`
- **전략**: `directInsert`
- **테스트 위치**: 일반 텍스트 모드
- **비고**: 최다 속성 (13개), Notes와 동일, NSAttachment 포함

### Pages (com.apple.iWork.Pages)
- **Attributes**: `["NSBackgroundColor", "NSUnderline", "NSUnderlineColor", "NSColor", "NSFont", "NSMarkedClauseSegment", "NSDictationHiliteMarkedText"]`
- **전략**: `directInsert` (NSMarkedClauseSegment + NSFont)
- **테스트 위치**: 새 문서
- **비고**: NSGlyphInfo 없음 (예상과 다름), 7개 속성

### Notes (com.apple.Notes)
- **Attributes**: `["NSFont", "NSUnderline", "NSColor", "NSBackgroundColor", "NSUnderlineColor", "NSMarkedClauseSegment", "NSLanguage", "NSTextInputReplacementRangeAttributeName", "NSGlyphInfo", "NSTextAlternatives", "NSTextInsertionUndoable", "NSAttachment", "NSDictationHiliteMarkedText"]`
- **전략**: `directInsert`
- **테스트 위치**: 새 노트
- **비고**: TextEdit과 완전히 동일 (13개), 같은 텍스트 엔진 사용 추정 

## ⚡ Electron 기반 앱

### VS Code (com.microsoft.VSCode)
- **Attributes**: `["NSUnderline", "NSUnderlineColor", "NSMarkedClauseSegment", "NSTextInputReplacementRangeAttributeName", "NSDictationHiliteMarkedText"]`
- **전략**: `swapMarked`
- **테스트 위치**: 편집기
- **비고**: Firefox, Slack, Discord와 완전히 동일, Chrome(1개)보다 풍부(5개)

### Slack (com.tinyspeck.slackmacgap)
- **Attributes**: `["NSUnderline", "NSUnderlineColor", "NSMarkedClauseSegment", "NSTextInputReplacementRangeAttributeName", "NSDictationHiliteMarkedText"]`
- **전략**: `swapMarked`
- **테스트 위치**: 메시지 입력란
- **비고**: VS Code, Firefox, Discord와 동일

### Discord (com.hnc.Discord)
- **Attributes**: `["NSUnderline", "NSUnderlineColor", "NSMarkedClauseSegment", "NSTextInputReplacementRangeAttributeName", "NSDictationHiliteMarkedText"]`
- **전략**: `swapMarked`
- **테스트 위치**: 채팅 입력란
- **비고**: Bundle ID가 예상(com.elbserver.elbclient)과 다름, VS Code/Firefox/Slack과 동일 

## 🔍 분석 및 인사이트

### Attribute 조합 패턴

#### directInsert를 트리거하는 조합
1. `NSTextAlternatives` 단독 포함
2. `NSMarkedClauseSegment` + `NSFont`
3. `NSMarkedClauseSegment` + `NSGlyphInfo`

#### 실제 측정된 고유 조합

**그룹 1: 최대 속성 세트** (13개)
- TextEdit, Notes
- 특징: NSTextAlternatives, NSGlyphInfo, NSAttachment 모두 포함

**그룹 2: Safari** (11개)
- NSTextAlternatives 포함, NSAttachment/NSGlyphInfo 없음

**그룹 3: Pages** (7개)
- NSFont, NSMarkedClauseSegment 포함, NSGlyphInfo 없음

**그룹 4: Electron 표준** (5개)
- Firefox, VS Code, Slack, Discord
- 특징: 모두 동일한 속성 세트

**그룹 5: iTerm2** (5개)
- NSFont 포함, NSMarkedClauseSegment 없음

**그룹 6: Xcode** (3개)
- NSMarkedClauseSegment + NSGlyphInfo 조합

**그룹 7: Terminal.app** (3개)
- 최소 속성, NSMarkedClauseSegment 없음

**그룹 8: Chrome** (1개)
- NSMarkedClauseSegment만

### 예외 케이스

1. **Pages의 의외성**
   - 고급 워드프로세서임에도 NSGlyphInfo 미지원
   - Safari보다 적은 속성 (7개 vs 11개)

2. **Electron vs Chrome 차이**
   - Electron 앱들(5개) > Chrome(1개)
   - Chrome 기반이지만 더 풍부한 속성 지원

3. **Terminal.app의 예상 불일치**
   - 빈 배열 예상했으나 3개 속성 있음
   - iTerm2보다 적음 (3개 vs 5개)

4. **Discord Bundle ID**
   - 예상: com.elbserver.elbclient
   - 실제: com.hnc.Discord
   - (한글과컴퓨터 버전으로 추정)

## 📅 업데이트 이력

- **2026-02-05 21:00**: 초기 템플릿 생성 (macOS 15.7.2 Sequoia)
- **2026-02-05 22:16**: 전체 12개 앱 측정 완료
- **[향후]**: macOS 메이저 업데이트 시 재측정 필요

## 🔗 관련 파일

- 전략 판별 로직: `macOS/Patal/HangulProcessor.swift:33-44`
- 로그 수집 코드: `macOS/Patal/HangulProcessor.swift:129-135`
- 테스트 코드: `macOS/PatalTests/InputStrategyTests.swift`
- 전략 적용: `macOS/Patal/PatalInputController.swift:49-82`

## 📖 측정 가이드

### 준비 단계
```bash
# 1. Debug 빌드 및 설치
make install-debug

# 2. 로그 모니터링 (별도 터미널)
make log | tee ~/Desktop/patal-attributes-$(date +%Y%m%d).log
```

### 측정 방법
1. 위 앱 목록의 각 앱 실행
2. 지정된 테스트 위치에서 한글 입력 시도 (예: "ㄱ")
3. 로그에서 `[bundleId] validAttributes: [...]` 패턴 확인
4. 이 문서의 해당 섹션에 측정값 기록
5. InputStrategy.determine() 결과 확인하여 전략 기록

### 로그 필터링
```bash
# 로그에서 validAttributes만 추출
grep "validAttributes" ~/Desktop/patal-attributes-*.log

# 앱별로 그룹화
grep "validAttributes" ~/Desktop/patal-attributes-*.log | sort | uniq
```
