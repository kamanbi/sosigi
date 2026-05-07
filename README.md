# sosigi

개인화 뉴스 수집 Flutter 앱입니다. (v1.0.1+13)

## 핵심 구성

- 상태관리: `flutter_riverpod`
- 저장소: `Hive` 기반 로컬 저장
- 마이그레이션: 기존 `SharedPreferences` 데이터는 첫 실행 시 Hive로 1회 이전
- 뉴스 수집: RSS 병렬 수집 + 키워드 매칭 + 의미 기반 중복 제거
- 카테고리: 정치 / 경제 / 사회 / 국제 / IT / 스포츠 / 연예 / 키워드 / 미분류
- 광고: `google_mobile_ads` (배너 광고 + 종료 인터스티셜)
- 알림: `flutter_local_notifications` + 백그라운드 동기화
- 로그: `AppLogger` 공통 로깅 유틸리티

## 시작

```bash
flutter pub get
flutter run
```

## 프로젝트 구조

```
lib/
  app/              # 앱 진입점, 라우터, 테마
  background/       # 백그라운드 동기화 entrypoint
  core/
    ads/            # 광고 ID 및 서비스 (인터스티셜, 카운터)
    enums/          # HomeCategory
    utils/          # JSON 유틸리티
  data/             # 기본 뉴스 소스 목록
  domain/models/    # Article, AppSettings, KeywordItem, NewsSource
  presentation/
    pages/          # home, settings, keyword_manage, news_sources, app_info, diagnostics, splash
    providers/      # Riverpod 프로바이더
    widgets/        # 공통 위젯 및 화면별 위젯
  services/
    local_store_service.dart     # Hive 스토리지 + SharedPreferences 마이그레이션
    rss_service.dart             # RSS 수집, 중복 제거, 카테고리 추론
    news_refresh_service.dart    # 뉴스 새로고침 오케스트레이션 + 리프레시 리스
    background_sync_scheduler.dart # WorkManager 기반 백그라운드 스케줄러
    notification_service.dart    # 로컬 알림 발송
    app_logger.dart              # 공통 로그 유틸리티
```

## 로컬 저장

앱 시작 시 [lib/services/local_store_service.dart](lib/services/local_store_service.dart)에서 Hive box를 초기화합니다.  
기존 버전의 `SharedPreferences` 데이터가 있으면 자동 마이그레이션됩니다.

저장 항목:
- 설정 (Wi-Fi 전용, 동기화 주기, 기사 보존 기간)
- 키워드 목록 / 뉴스 소스 목록 / 기사 캐시
- 읽음 기사 ID 목록 / 북마크 기사 ID 목록
- 알림 전송 키 목록 / 알림 권한 거절 횟수
- 마지막 동기화 시간 / 마지막 백그라운드 동기화 결과
- 리프레시 리스 (동시 새로고침 방지용 락)

## 설정 옵션

| 항목 | 기본값 | 선택지 |
|------|--------|--------|
| Wi-Fi 전용 수집 | 켜짐 | 켜짐 / 꺼짐 |
| 동기화 주기 | 1시간 | 15분 / 30분 / 1시간 |
| 기사 보존 기간 | 120h | 72h / 96h / 120h |

## 광고

- 배너 광고: 홈, 설정 화면에 노출
- 종료 인터스티셜: 앱 종료 시 일정 횟수 기사 열람 후 노출
- 테스트 기기 ID는 `main.dart`의 `testDeviceIds`에 등록

## 백그라운드 동기화

WorkManager를 통해 설정된 주기로 RSS를 수집하고 키워드 일치 기사에 알림을 발송합니다.  
Android 네이티브 코드: `android/app/src/main/kotlin/com/kaman/sosigi/`

## Android 릴리즈 서명

릴리즈 키스토어를 쓰려면 `android/key.properties.example`을 복사해 `android/key.properties`로 만든 뒤 값을 채우면 됩니다.

```properties
storeFile=../release-keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

`android/key.properties`가 없으면 현재 설정은 debug signing으로 fallback 합니다.
