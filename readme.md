# Patal Input Method

P2 커스텀 배열 기반의 입력기 

## 신세벌식

- 숫자키를 사용하지 않는 세벌식 
- 조성은 오른쪽, 중성과 종성은 왼쪽
- 조합 상태에 따라 중성과 종성을 선택하는 오토마타
- 'ㅋㅋㅋ', 'ㅊㅋㅊㅋ' 같은 입력 가능

## 특수 기능

- Esc 키를 입력하면 영문 상태로 전환
- Spotlignt 에 진입할 때 영문 상태로 전환
- 내장된 영문 자판 사용시 더 빠른 한/영 전환

## Note

인터페이스 구성은 대체적으로 XIB 를 사용하는게 좋아 보인다.

- https://stackoverflow.com/questions/22524232/which-is-more-efficient-way-storyboard-or-xib

오래된 글이긴 하지만 아직도 유효한 듯 하다. 필요하다면 나중에는 SwiftUI 를 쓰는게 어떨까 싶다.

## TO DO
