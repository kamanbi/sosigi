# sosigi

개인화 뉴스 수집 Flutter 앱입니다.

## 핵심 구성

- 상태관리: `flutter_riverpod`
- 저장소: `Hive` 기반 로컬 저장
- 마이그레이션: 기존 `SharedPreferences` 데이터는 첫 실행 시 Hive로 1회 이전
- 뉴스 수집: RSS 병렬 수집 + 키워드 매칭
- 광고: `google_mobile_ads`
- 알림: `flutter_local_notifications`

## 시작

```bash
flutter pub get
flutter run
```

## 로컬 저장

앱 시작 시 [lib/services/local_store_service.dart](lib/services/local_store_service.dart)에서 Hive box를 초기화합니다.
기존 버전의 `SharedPreferences` 데이터가 있으면 자동 마이그레이션됩니다.

## Android 릴리즈 서명

릴리즈 키스토어를 쓰려면 `android/key.properties.example`을 복사해 `android/key.properties`로 만든 뒤 값을 채우면 됩니다.

```properties
storeFile=../release-keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

`android/key.properties`가 없으면 현재 설정은 debug signing으로 fallback 합니다.
