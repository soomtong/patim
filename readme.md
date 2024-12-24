# Patal Input Method

팥알님의 한글 배열을 지원하는 입력기

## 세벌식 자판

공병우님이 만든 세벌식 자판이 가장 널리 사용되고 있습니다. [간략한 소개](https://세벌식.kr)

세벌식 자판이 많이 사용되지는 않습니다만 두벌식 자판(KS X 5002)과 함께 윈도우즈 운영체제와 맥OS에서 공식 지원되고 있습니다.

- 초성은 오른손, 중성과 종성은 왼손
- 자주 사용되는 글자를 중심으로 자판을 배열
- 영문에는 드보락[dvorak](https://en.wikipedia.org/wiki/Dvorak_keyboard_layout)이라는 자판이 인체공학적 배열을 목표로 고안되어 사용되고 있음

### 신세벌식 자판

신광식님이 만든 첫/가/끝(첫소리 가운뎃소리 끝소리) 갈마들이 세벌식 자판

- 조합 상태에 따라 중성과 종성을 선택하는 오토마타
- 숫자키를 사용하지 않는 자판

### 자판의 글자 수

- 두벌식: 26개; 표현 가능한 낱자의 수 33개
- 세벌식: 39개; 표현 가능한 낱자의 수 52~58개
- 신세벌식: 29개; 표현 가능한 낱자의 수 46개

### 추천 자판

팥알님의 추천 자판은 다음과 같습니다.

- 신세벌식인 경우 `P2` 자판: 숫자열을 사용하지 않는 첫/가/끝 갈마들이 [자판](https://pat.im/1136) 배열입니다.
    - 신세벌 P2: 2016~2018년에 공개/개선된 P2 자판
- 세벌식인 경우 `3-P` 자판: 공세벌식에 익숙한 사용자들에게 [추천](https://pat.im/1128)합니다.
    - 공세벌 3-P: 2015년 완성된 공세벌 자판 (P2/P3: 2줄/3줄 숫자 배열 옵션)
    - 공세벌 2012: 390자판의 개선안
    - 공세벌 2011: 391자판의 개선안

## 지원하는 자판

입력기의 이름이 팥알입력기인 만큼 팥알님의 주요 자판을 지원합니다.

- [ ] 신세벌식: [문서 링크](https://pat.im/1136) [배열 이미지 링크](https://pat.im/attach/1/6039194145.png)
- [ ] 공세벌식 (2줄/3줄 숫자 배열 옵션): [문서 링크](https://pat.im/1128) [배열 이미지 링크1](https://pat.im/attach/1/9648972827.png) [배열 이미지 링크2](https://pat.im/attach/1/8451389149.png)
- [ ] 신세벌식 P2커스텀: `ㅋ`,`ㅌ` 의 위치가 `>`,`<` 로 이동된 자판입니다. `50%` 이하 배열 키보드를 고려하였고, 입력기 개발자 개인 취향의 배열이 적용되어 있습니다. 
