# FlickrGallery


# 빌드 방법
iOS 10.0 >=, Xcode 10.1 >=, CocoaPod 1.6.0 >= 가 설치된 환경에서에서 빌드가능합니다.

1. FlickrGallery-master 프로젝트를 원하는 경로에 다운 받습니다. (ex: ~/Desktop)
2. ~/Desktop/FlickrGallery-master 으로 이동합니다.
3. 경로 최상단에 Podfile이 보이면 올바르게 이동한 것 입니다.
4. 터미널을 통해 pod install 명령어를 입력해주세요.
5. FlickrGallery.xcworkspace 파일이 생성되면 Xcode로 열어주세요.
6. FlickrGallery 모듈을 타겟으로 빌드해주세요.
7. 혹시 빌드가 안된다면 GalleryDomain 모듈 -> FlickerService 모듈 -> FlickrGallery 모듈순으로 빌드를 진행해주세요.
8. 감사합니다.

# 부가 정보

1. 플리커 피드에 새로운 이미지가 없다면 새로운 이미지 출현시까지 대기합니다.


[기본 구현 요구 사항]

아래 Flickr API 를 이용한다. (format 은 자유롭게 변경 할 수 있다.)
```

https://api.flickr.com/services/feeds/photos_public.gne?tags=landscape,portrait&tagmode=any

```
피드의 목록에 있는 이미지를 모두 보여준 경우 새로운 피드 목록의 이미지를 보여줘야 한다. 다음 피드 목록의 이미지를 보여줄때 딜레이(목록 요청 시간 등)가 없어야 한다.
이미지 전환 효과는 fade-in, fade-out 을 구현하고 전환 효과 시간은 이미지가 보여지는 시간에서 제외한다.
인터넷 연결이 끊기면 유저에게 알려 준다.
Swift 4.2 or above 로 작성한다.
Deployment taget >= iOS 10.0
Portrait/Landscape 지원해야 한다.
아이패드에서도 동작하는 유니버설 앱이어야 한다.
iPhone Notch 지원해야 한다.
Cocoapods, Carthage 사용 할 수 있다.
Autolayout 사용해야 한다.
README.md 에 빌드 방법이 포함되어야 한다.
SwiftLint 를 사용한다. 설정은 이 .swiftlint.yml 파일을 이용 한다.

[사용자 스토리]
앱을 실행하면 시작 화면이 보인다.
시작 화면에서 이미지 하나가 보이는 시간(1초~10초)을 설정할 수 있다.
시작 화면에서 "시작" 버튼을 누르면 슬라이드쇼 시작할 수 있다.
슬라이드쇼 화면에서도 이미지 하나가 보이는 시간(1초~10초)을 변경할 수 있다.
슬라이드쇼 중 시작 화면으로 돌아갈 수 있다.
모든 화면에서 디바이스를 회전하면 현재 화면이 회전한다.
앱에서 인터넷 연결 끊김 여부를 유저가 확인할 수 있다.
