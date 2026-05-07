# CLAUDE.md — sosigi 개발 가이드

## 빠른 시작

```bash
flutter pub get
flutter run                   # 디버그 실행
flutter build apk --release   # Android 릴리즈 빌드
```

## 아키텍처

- **상태관리**: Riverpod (`flutter_riverpod`)
- **저장소**: Hive 단일 Box (`sosigi_app_box`)
- **라우팅**: `app/router.dart` (GoRouter 계열)
- **진입점**: `lib/main.dart` → `LocalStoreService.initialize()` → `_initializeStartupServices()`

## 주요 서비스 (lib/services/)

| 파일 | 역할 |
|------|------|
| `local_store_service.dart` | Hive 박스 초기화, SharedPreferences 마이그레이션, 전체 데이터 CRUD |
| `rss_service.dart` | RSS 병렬 수집, 의미 기반 중복 제거, 카테고리 자동 분류 |
| `news_refresh_service.dart` | 새로고침 오케스트레이션 + 리프레시 리스(동시 실행 방지) |
| `background_sync_scheduler.dart` | WorkManager 스케줄 등록/취소 |
| `notification_service.dart` | 키워드 일치 기사 알림 발송 |
| `app_logger.dart` | 공통 로그 유틸 (`AppLogger.info/error`) |

## 도메인 모델 (lib/domain/models/)

- `Article`: 기사 (id, sourceId, title, link, summary, publishedAt, category, matchedKeywords, isKeywordMatched)
- `NewsSource`: 뉴스 소스 (id, provider, url, category, enabled)
- `KeywordItem`: 키워드 (id, name)
- `AppSettings`: 설정 (wifiOnly, suppressMobileDataWarning, syncInterval, retentionOption)

## 카테고리 (HomeCategory)

`all` / `politics` / `economy` / `society` / `international` / `it` / `sports` / `entertainment` / `keyword` / `uncategorized`

카테고리 추론 로직: `RssService._inferCategory()` — 스포츠를 IT보다 먼저 검사하여 오분류 방지.

## 광고

- 광고 ID: `lib/core/ads/ad_ids.dart`
- 종료 인터스티셜: `ExitInterstitialAdService` (싱글턴)
- 기사 열기 카운터: `ArticleOpenAdCounterService`

## Hive 저장 키 (local_store_service.dart 상수 참조)

리프레시 리스(`_refreshLease`)는 동시에 여러 곳에서 새로고침을 트리거할 때 충돌을 막는 뮤텍스 역할을 합니다.

## 뉴스 소스 기본값

`lib/data/default_news_sources.dart`의 `runtimeDefaultNewsSources` 기준.  
저장된 소스와 런타임 기본값을 `_reconcileSourcesWithRuntimeDefaults()`로 병합 — 신규 소스는 자동 추가, 기존 소스의 enabled 상태는 유지.

## 백그라운드 동기화 (Android)

- Dart 측: `lib/background/background_sync_entrypoint.dart`
- Kotlin 측: `android/app/src/main/kotlin/com/kaman/sosigi/`
  - `NewsSyncWorker.kt`: WorkManager Worker
  - `BackgroundSyncScheduler.kt`: 스케줄 등록
  - `MainActivity.kt`: Flutter 플러그인 초기화

## 코드 작성 원칙 (AGENTS.md)

1. **Research → Plan → Implement** 순서를 따른다.
2. 가독성 5칙 적용: Early Return, Contextual Naming, Magic Number Hunter, Parameter Object, Complexity Check.
3. 사용자 `승인` / `OK` 전까지 구현 코드를 작성하지 않는다.
4. `research.md`와 `plan.md`를 경유한 뒤 구현한다.

## 자주 쓰는 명령

```bash
flutter analyze                  # 정적 분석
flutter test                     # 테스트 실행
flutter pub outdated             # 패키지 버전 확인
adb logcat -s flutter            # Android 로그 확인
```
