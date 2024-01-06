## Note

개발 일지

### Day 4

기본 앱 구성에서 `ESC` 키를 누르면 라틴 자판으로 변경되는 구성부터 제작하려고 한다. 내게는 자판 배열보다 더 중요한 기능이다.

1. 아무 키를 누르면 'ㅎ' 이 출력되도록
2. 기본 라틴 입력기 확보
3. 자판 전환 및 아이콘 전환

### Day 3

작업 순서를 정해야 한다. 아직 스케폴딩 단계니 입력기의 오토마타 구현 전 앱의 구성을 먼저 세팅한다.

1. 메뉴 아이콘, 입력기 이름과 입력기 아이콘
2. 자판 배열은 두 개 이상 제공할 수 있도록 appId 구성
3. 키 입력을 받아 로거로 출력: 반드시 esc 키 입력을 받아야 한다. 알파뉴메릭 외, 시스템의 제어키를 받을수 있도록 하자.
4. 라틴 입력기로 자동 변환하는 코드
5. 기본적인 테스트 코드

최신 맥OS 의 번들 입력기에 있는 Info.plist 를 참조하여 파악한 내용은 다음과 같다.

TIS 로 시작하는 key 와 tsInputMethod 로 시작하는 key 가 중요하다.

입력기 선택 과정에 한글 영역에 추가할 입력기가 등록되도록 하려면, `TISIntendedLanguage` 의 값이 `ko` 여야 한다.
`en` 인 경우는 영문 레이아웃 항목에 추가된다.
입력기에 대한 세팅은 Info.plist 의 root 에 있는 항목과 `ComponentInputModeDict` 아래에 있는 항목에 추가할 수 있는데,
root 에 입력할 필요는 없는 듯 하다.

> "TISIntendedLanguage" - 입력 소스에서 입력하려는 기본 언어를 지정하는 키입니다. 예를 들어 유니코드 16진수 입력 키 레이아웃과 같이 아무 키도 없는 경우에는 이 키를 지정할 필요가 없습니다. 언어는 BCP 47(RFC 3066의 후속 버전)에 설명된 형식의 문자열로 표시됩니다.

입력기의 아이콘 사이즈가 변했다. 예전보다 가로 폭이 더 커졌다. 
그리고 알파(투명)가 있는 파일에 대해 템플릿 형태의 아이콘을 구성할 수 있게 되었다.
이 경우 `TISIconIsTemplate` 키를 통해 이 기능을 활성화 할 수 있다.
착각한 것은 최신 OS 에서 아이콘을 표현하기 위해 이미지 대신 문자를 직접 렌더링하는 것으로 생각했는데, 그냥 알파 처리된 파일을 사용할 수 있게 개선 된 것이었다.
아마 macOS 13 정도부터 도입된 듯 하다.

```xml
<key>TISIconIsTemplate</key>
<true/>
```

예전처럼 풀컬러 이미지 아이콘을 사용하는 경우 false 로 두면 된다.

macOS 14 버전부터 입력 모드에서 입력기가 변경될 때 현재 입력 언어를 표시해주는 툴팁이 커서 근처에 잠깐씩 보이는 기능이 추가되었다. 
이 때 나타나는 문자도 어딘가 지정하는 것 같은데 아직 파악하지 못했다. 한글 두 글자 정도의 폭도 표현이 가능했다.

몇 가지 실험을 통해 신기한 꼼수를 발견했다. 구현체는 다르더라도 시스템 입력기의 리소스를 사용할 수 있다.
예를 들어 `TISInputSourceID` 키의 값을 `com.apple.inputmethod.Korean.***` 를 사용하면 내장 한글 입력기에서 제공하는 아이콘과 라벨을 사용할 수 있다. 
하지만 실제 입력기는 시스템 입력기가 아닌 `tsInputModeListKey` 에서 정의한 입력기가 실행된다.

이 방식으로 메뉴 아이콘과 입력기 아이콘, 그리고 입력모드에 따라 잠깐씩 나타나는 라벨 아이콘을 구성할 수 있다.
이상하긴 하지만 우선 이렇게 진행해보자.

### Day 2

클래스 이니셜라이저의 종류가 하나가 아님. 기본 init 은 designated 의 상태고 convenience 타입의 init 이 추가된 형태.
designated 보다 먼저 실행되는 듯. 단순히 override 하는 것보다 composite 하는게 편리한 경우가 있으니...

- https://www.hackingwithswift.com/example-code/language/what-are-convenience-initializers
- https://choi-log-life.tistory.com/entry/iOS-Swift-initialization-3

outlet 으로 인터페이스와 연동하도록 하고 앱을 background 로 동작시키지 위해 `LSBackgroundOnly` 값을 추가한다.
입력기에 등록시키기 위해 InputMethodServer 로 시작하는 키도 추가해야 한다.

### Day 1

인터페이스 구성은 대체적으로 XIB 를 사용하는게 좋아 보인다.

- https://stackoverflow.com/questions/22524232/which-is-more-efficient-way-storyboard-or-xib

오래된 글이긴 하지만 아직도 유효한 듯 하다. 필요하다면 나중에는 SwiftUI 를 쓰는게 어떨까 싶다.

AccentColor 라는 내용이 Assets.xcassets 에 추가되었는데 이게 뭔가...

- https://mcmw.abilitynet.org.uk/changing-system-accent-colour-macos-1015-catalina

@main 어노테이션은 무엇인가?

main.swift 를 따로 만들지 않아도 되도록 필요한 과정을 구성한다.

- https://medium.com/@abedalkareemomreyh/what-is-main-in-swift-bc79fbee741c
- https://useyourloaf.com/blog/what-does-main-do-in-swift-5.3/

AccentColor 를 지정하고 @main 에서 NPE 같은게 발생했다.

우선 AccentColor 지정을 해제하니 정상 실행된다...

앱 실행 후 노티 출력하는 기능은 NotificationCenter 에 정의되어 있는 기능을 사용하는 걸로 보인다.

- http://seorenn.blogspot.com/2014/11/osx.html
- https://learnappmaking.com/notification-center-how-to-swift/
- https://www.youtube.com/watch?v=mIztoF9CzP8

NSUserNotificationCenter 는 빅서에서 deprecated 되는데?

시스템 설정에서 노티피케이션 세팅값을 지우는 건 그냥 `delete` 키로 가능...
이것도 안해보고 한참 찾았다.

- https://apple.stackexchange.com/questions/84075/remove-an-app-from-notification-center-preference-pane

제작중인 앱의 항목을 지우고 다시 실행하면 처음처럼 세팅할 수 있다.

Trailing closure 패턴에 익숙해져야 한다.



