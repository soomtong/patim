## Note

개발 일지

### Day 10

세벌식 입력기 구성 방법: 시나리오

- 별도의 조합 상태를 가지고 있을 필요가 있나? preedit 과 commit 으로 상태를 알수 있을 것 같다.
- 초성/중성/종성 정보를 따고 가지고 있어야 하나? 세벌식의 장점을 살리는 방향(모아치기 지원, 도깨비불 방지)으로 구성해보자.

글자가 입력된다. 이 글자는 rawChar 라고 하자.
입력된 글자를 한글로 변환한다. 모아치기를 구성할 수 있게 하려면 초성이 먼저 입력되지 않는 경우도 대비해야 한다.
한글이 아닌 경우에는 return false 로 입력기를 종료한다. flush 할 필요도 없다.

초성인가? preedit 에 초성을 넣는다. 각 자소는 unichar 값을 넣어도 되고, 한글 낱자를 넣어도 될 듯.
preedit 의 값을 setMarkedText 로 화면에 출력한다.

그 다음 글자가 조합 가능하지 않은 글자라면 preedit 을 commit 으로 전달하고 새 글자를 preedit 에 넣는다.
조합 가능한 상태와 그렇지 않은 상태는 어떻게 구분하나?
초성/중성/종성 프로퍼티에 값이 없으면 추가할 수 있으니 알수 있지 않을까?
입력된 글자가 초성인데 preedit 에 초성이 있으면 조합 불가. 그런데 쌍자음이 가능한 경우라면?
입력된 글자가 종성인데 preedit 에 종성이 없으면 조합 가능. 입력된 글자가 중성인데 preedit 에 중성이 없으면 조합 가능.
입력된 글자가 초성인데 preedit 에 초성과 중성이 있으면 commit 해야 하겠지? 모아치기를 고려한다고 하더도 완성된 글자에 겹초성을 하지 않아야 한다.
`kk` --> `ㄲ`, `kh` --> `ㄱㄴ`, `h1` --> `ㄴ1`

<https://ko.wikipedia.org/wiki/한글_낱자_목록>

그러면 preedit 은 초성/중성/종성을 프로퍼티로 가지는 구조체여야 하는가?
preedit 을 거치지 않는 글자가 있을까? 모아치기를 고려한다면 모든 입력 글자는 preedit 에 담겨야 할 것이다.

commit 에 글자가 있으면 insertText 를 통해 화면에 출력하고 preedit 의 값을 setMarkedText 로 출력한다.

### Day 9

입력기가 아예 올라오지 않던 문제를 우회한 듯 하다.
하나의 입력기에 두 개 자판을 처리하는게 잘 안되네... 아니 한글 입력기나 일어 입력기는 되는데...

입력되는 키코드를 조합할 수 있는 한글 자소 낱자로 변환하고 조합된 글자를 출력하기 위해서 유니코드 조합을 이해해야 한다.
[한글과 유니코드](https://gist.github.com/soomtong/b51861a440e0bfdc58008deb8078d465)

글자를 삭제하는 과정은 조합하는 것의 반대이긴 하지만 자소가 분리되는 과정을 겪어야 한다.
자소를 조합하는 코드와 분리하는 코드를 하나의 클래스로 담아둔다.
[유니코드를 한글 자소로 분리하는 방법](https://github.com/intotherealworld/jamo)

### Day 8

Swift 6 으로 업그레이드 되면서 main 애플리케이션 구성이 달라졌다. `@main` 어트리뷰트를 사용해야 한다.
동시성 문제도 보강되어 기존 전역 변수 IMKServer 를 사용할 수 없다. 그리고 Swift 용 테스트 스위트가 추가되었다!

Swift 6 언어 레벨로 추천 코드를 받아 빌드가 성공해도 입력기가 로드되지 못해 테스트 케이스는 Swift 6 을 타겟으로 하고 나머지는 Swift 5 를 언어 레벨로 지정하고 진행하자.

지금 사용하는 입력기 핸들러 타입은 opt 키 같은 걸 따로 받는 것은 안되는 듯 하다. 우선 string 만 받아서 입력기 구성을 먼저 하자.
어짜피 OS 에서 내려주는 문자열을 조합하여 한글을 구성하는 가장 단순한 형태의 입력기를 만들고 있으니, 사용처가 아직 명확하지 않은 keyCode 나 flags 는 제거한다.

Swift 6 에 XCTest 대신 사용할 수 있는 테스트 스위트가 들어와 다행이다.
덕분에 리그레션 테스트를 할 수 있게 되었다. 우당탕탕 '강남' 글자를 조합할 수 있게 되었다.
아직 화면에는 조합 과정을 처리하지 않고 있지만 입력기가 정상적으로 동작하는 것을 확인할 수 있었다.

![iTerm2](./misc/SCR-20241123-trpi.png)
![Finder](./misc/SCR-20241123-tolm.png)

입력기가 아예 전환되지 않는 앱이 있다. 지금 MarkEdit 입력 환경에서 아예 입력기가 올라오지 않는다.
맥의 기본 에디터TextEdit 에서도 입력기가 올라오지 않는다.

### Day 7

애플리케이션 구성 복기.

IMKServer 클래스가 반드시 필요하다. 이 프레임워크는 InputMethodKit 을 필요로 하고 NS 프레임워크를 사용할테니 Cocoa 도 필요하다.
imkServer 가 생성되면 시스템에 의해 호출된다. 그래서, 별도로 호출하는 코드가 보이지 않는다.

실제 코드는 IMKInputController 를 구현하는implement 것이다.
이 클래스는 open 인 경우도 있고 internal 로 scope 를 제한해도 동작하는 듯 하다.

클래스 안에서 몇 가지 method 를 override 로 구현한다. 가장 적절한 `inputText(string, keyCode, flags)` 를 사용하기로 했다.

`esc` 키를 통해 latin 자판으로 변경하는 기능은 배제했다. 입력기 구현을 먼저 진행하고 부가적인 기능은 나중으로 미룬다.

이제 오토마타를 구현해야 하는데 우선 키 조합은 string 을 사용하는 구현을 먼저 진행하려고 한다.
추후 다양한 응용을 위해 키코드를 통해 조합을 하는 것도 고려하고 있다.

### Day 6

각 입력기의 인풋 소스 아이디를 알아야 한다. 보통 `Info.Plist` 에 `TISInputSourceID` 로 정의되어 있다.
TISInputSourceID 는 `com.apple.inputmethod.Korean.2SetKorean` 와 같은 형태로 정의되어 있다.
내가 사용하는 구름입력기의 경우 영문은 `org.youknowone.inputmethod.Gureum.system` 이고 한글은 `org.youknowone.inputmethod.Gureum.han3shin` 이다.

입력기 전환 매커니즘은 `https://github.com/laishulu/macism` 를 참고했다.
입력기의 SourceID 목록을 가져와야 한다. 이 목록 가져오는 것은 `https://github.com/hatashiro/kawa` 를 참고했다.

### Day 5

입력기를 점검할 때 맥OS에 새로운 계정을 하나 만들고 개발 환경을 로그아웃하지 않고 새 계정에서 입력기 상태를 점검하는 방법을 사용하기 시작했다.
공용 사용을 위해 빌드된 앱은 `/Library/Input Methods/` 로 복사해 가며 점검한다.

하다보니 새 계정 없어도 되더라. `killall Patal` 해서 메모리에서 제거하고 다시 설치해 사용할 수 있더라. 그래도 간혹 필요할지 모르니 생성한 계정은 그냥 두기로 한다.

`NSLog` 는 콘솔 앱에 로그가 출력되나 `print` 는 찾을 수 없었다.

> 휴. 아직 NSLog 사용법도 모른다...

`import os.log` 와 `os_log` 를 알게 됨. NSLog 은 더이상 사용하지 않아도 되겠다. 하지만 이건 Objective-C 에서 쓸 때 사용하고, `Logger` 클래스를 쓰면 된다.
그런데 왜 콘솔 앱에서 private 로 나오는건가... 보안 강화 때문이구나.

> <https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code>

- [x] subsystem, category, log level 도 추가해 사용해보자.

`ESC` 키를 누르면 라틴 자판으로 변경되는 구성을 만들자.

키코드는 `53` 이다.

`inputText` 를 override 하는 경우 몇 몇 앱에서 `ESC` 를 캡쳐하지 못한다. 하지만 iTerm 이나 wezTerm 에서 잘 작동한다. 우선 지금 상태로 구현해보자.
그리고 일반 GUI 앱에서는 잘 동작한다.

```shell
log stream --predicate 'subsystem=="com.soomtong.inputmethod.Patal"' --debug --style compact --type log
```

콘솔 앱에서 보이지 않는 메시지가 터미널 로그 명령으로 보인다. 그냥 위 명령을 쓰는게 좋겠다.

그리고 또 알게된 사실. `inputText` 로 입력이 안되는 앱이 좀 있는 듯 하다. 일반 GUI 앱은 잘 되지만,
~~내가 사용하는 zsh 세팅의 + wezterm 에서 한글 입력이 되지 않는다.~~ 그런데 iterm 에서는 잘 된다.
그냥 `handle` 써야 하나보다. 하지만 우선 이 상태로 먼저 구현해 보자. 세세한 튜닝은 나중에 해도 된다.

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

- <https://www.hackingwithswift.com/example-code/language/what-are-convenience-initializers>
- <https://choi-log-life.tistory.com/entry/iOS-Swift-initialization-3>

outlet 으로 인터페이스와 연동하도록 하고 앱을 background 로 동작시키지 위해 `LSBackgroundOnly` 값을 추가한다.
입력기에 등록시키기 위해 InputMethodServer 로 시작하는 키도 추가해야 한다.

### Day 1

인터페이스 구성은 대체적으로 XIB 를 사용하는게 좋아 보인다.

- <https://stackoverflow.com/questions/22524232/which-is-more-efficient-way-storyboard-or-xib>

오래된 글이긴 하지만 아직도 유효한 듯 하다. 필요하다면 나중에는 SwiftUI 를 쓰는게 어떨까 싶다.

AccentColor 라는 내용이 Assets.xcassets 에 추가되었는데 이게 뭔가...

- <https://mcmw.abilitynet.org.uk/changing-system-accent-colour-macos-1015-catalina>

@main 어노테이션은 무엇인가?

main.swift 를 따로 만들지 않아도 되도록 필요한 과정을 구성한다.

- <https://medium.com/@abedalkareemomreyh/what-is-main-in-swift-bc79fbee741c>
- <https://useyourloaf.com/blog/what-does-main-do-in-swift-5.3/>

AccentColor 를 지정하고 @main 에서 NPE 같은게 발생했다.

우선 AccentColor 지정을 해제하니 정상 실행된다...

앱 실행 후 노티 출력하는 기능은 NotificationCenter 에 정의되어 있는 기능을 사용하는 걸로 보인다.

- <http://seorenn.blogspot.com/2014/11/osx.html>
- <https://learnappmaking.com/notification-center-how-to-swift/>
- <https://www.youtube.com/watch?v=mIztoF9CzP8>

NSUserNotificationCenter 는 빅서에서 deprecated 되는데?

시스템 설정에서 노티피케이션 세팅값을 지우는 건 그냥 `delete` 키로 가능...
이것도 안해보고 한참 찾았다.

- <https://apple.stackexchange.com/questions/84075/remove-an-app-from-notification-center-preference-pane>

제작중인 앱의 항목을 지우고 다시 실행하면 처음처럼 세팅할 수 있다.

Trailing closure 패턴에 익숙해져야 한다.
