## Note

개발 일지

### Day 2

클래스 이니셜라이저의 종류가 하나가 아님. 기본 init 은 designated 의 상태고 convienience 타입의 init 이 추가된 형태.
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


