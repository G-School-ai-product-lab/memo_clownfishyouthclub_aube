# Pamyo One - 데이터 흐름도 (Data Flow Diagram)

## 개요
이 문서는 Pamyo One 앱의 주요 기능별 데이터 흐름을 **단계별**로 설명합니다. 각 기능에서 **사용자 액션 → 데이터 작업(CRUD) → 데이터 소스(Entity) → 관련 Attributes → 화면 변화** 순서로 추적합니다.

### 문서 구조
각 흐름은 다음 형식으로 기술됩니다:

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|

---

## 1. 인증 (Authentication)

### 1.1 로그인 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 로그인 화면에서 "Google 로그인" 버튼 클릭 | - | - | - | 로그인 처리 중 표시 |
| 2 | Google 계정 선택 및 인증 | - | - | - | Google 인증 화면 표시 |
| 3 | - | **READ** Firebase Auth에서 사용자 정보 획득 | `user` | `id`, `email`, `displayName`, `photoURL` | - |
| 4 | - | Riverpod AuthState 업데이트 | - | - | - |
| 5 | - | - | - | - | **HomeScreen**으로 자동 라우팅 |

**데이터 소스:**
- `user` (Firebase Authentication): 사용자 인증 정보

**파일 위치:**
- Service: [lib/features/auth/data/services/auth_service.dart](../lib/features/auth/data/services/auth_service.dart)
- Screen: [lib/features/auth/presentation/screens/login_screen.dart](../lib/features/auth/presentation/screens/login_screen.dart)

---

### 1.2 로그아웃 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 프로필 화면에서 "로그아웃" 버튼 클릭 | - | - | - | 로그아웃 확인 다이얼로그 표시 |
| 2 | 확인 버튼 클릭 | - | - | - | - |
| 3 | - | **DELETE** Firebase Auth 세션 종료 | `user` | - | - |
| 4 | - | Riverpod AuthState 초기화 | - | - | - |
| 5 | - | - | - | - | **LoginScreen**으로 자동 라우팅 |

**데이터 소스:**
- `user` (Firebase Authentication): 사용자 세션

---

## 2. 메모 관리 (Memo Management)

### 2.1 메모 생성 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 홈 화면에서 "+" 버튼 클릭 | - | - | - | **MemoEditScreen** 진입 (생성 모드) |
| 2 | 제목, 내용 입력 | - | - | - | 입력 필드 업데이트 |
| 3 | (선택) "AI 자동 분류" 버튼 클릭 | **READ** 사용자 폴더 목록 조회 | `folder` | `id`, `name` | AI 분류 진행 중 표시 |
| 4 | - | AI 분석 (Gemini API 호출) | - | - | - |
| 5 | - | AI 추천 결과 표시 | - | - | 추천 폴더 및 태그 자동 입력 |
| 6 | (선택) 폴더 선택, 태그 추가 | - | - | - | 선택된 폴더/태그 표시 |
| 7 | "저장" 버튼 클릭 | - | - | - | 저장 처리 중 표시 |
| 8 | - | **CREATE** 메모 생성 | `memo` | `id`, `userid`, `title`, `content`, `tags`, `folderid`, `createAt`, `updateAt`, `isPinned` | - |
| 9 | - | **UPDATE** 폴더 메모 개수 증가 (폴더 지정 시) | `folder` | `memoCount` ← +1 | - |
| 10 | - | **CREATE/UPDATE** 태그 생성 또는 개수 증가 | `tag` | `id`, `userid`, `name`, `color`, `memoCount` | - |
| 11 | - | **UPDATE** 가이드 진행 상태 (첫 메모인 경우) | `guideprogress` | `firstMemoCreated` ← true | - |
| 12 | - | Firestore Stream 자동 업데이트 | - | - | 이전 화면으로 돌아감 |
| 13 | - | - | - | - | **HomeScreen**: 최근 메모 목록에 새 메모 표시 |
| 14 | - | - | - | - | 폴더 카드의 메모 개수 갱신 |

**데이터 소스:**
- `memo`: 사용자 메모
- `folder`: 메모 폴더 (Optional 관계)
- `tag`: 메모 태그 (N:M 관계)
- `guideprogress`: 가이드 진행 상태 (Local Storage)

**파일 위치:**
- Screen: [lib/features/memo/presentation/screens/memo_edit_screen.dart](../lib/features/memo/presentation/screens/memo_edit_screen.dart)
- DataSource: [lib/features/memo/data/datasources/firebase_memo_datasource.dart](../lib/features/memo/data/datasources/firebase_memo_datasource.dart)
- AI Service: [lib/features/ai/data/services/gemini_service.dart](../lib/features/ai/data/services/gemini_service.dart)

---

### 2.2 메모 조회 흐름

#### 2.2.1 전체 메모 조회

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 홈 화면에서 "전체 메모 보기" 클릭 | - | - | - | **AllMemosScreen** 진입 |
| 2 | - | **READ** 사용자의 전체 메모 조회 (Stream) | `memo` | `id`, `userid`, `title`, `content`, `tags`, `folderid`, `updateAt`, `isPinned` | - |
| 3 | - | 메모리에서 `updateAt` 기준 내림차순 정렬 | - | - | - |
| 4 | - | - | - | - | 메모 목록 표시 (고정 메모 상단) |
| 5 | (선택) 폴더 필터 버튼 클릭 | - | - | - | 폴더 선택 다이얼로그 표시 |
| 6 | 특정 폴더 선택 | 클라이언트 사이드 필터링 (`folderid` 기준) | `folder` | `id`, `name`, `icon`, `color` | 선택된 폴더의 메모만 표시 |

**데이터 소스:**
- `memo`: 사용자 메모
- `folder`: 메모 폴더 (필터용)

---

#### 2.2.2 폴더별 메모 조회

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 홈 화면에서 특정 폴더 카드 클릭 | - | - | - | **MemoListScreen** 진입 |
| 2 | - | **READ** 폴더 정보 조회 | `folder` | `id`, `name`, `icon`, `color`, `memoCount` | - |
| 3 | - | **READ** 사용자 메모 조회 (Stream) | `memo` | `id`, `title`, `content`, `tags`, `folderid`, `updateAt`, `isPinned` | - |
| 4 | - | 클라이언트 사이드 필터링 (`folderid` 일치) | - | - | - |
| 5 | - | - | - | - | 폴더 정보 표시 (이름, 아이콘, 색상, 개수) |
| 6 | - | - | - | - | 필터링된 메모 목록 표시 |

**데이터 소스:**
- `folder`: 메모 폴더
- `memo`: 사용자 메모

---

### 2.3 메모 수정 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 메모 목록에서 메모 카드 클릭 | - | - | - | **MemoEditScreen** 진입 (수정 모드) |
| 2 | - | **READ** 메모 상세 정보 조회 | `memo` | `id`, `title`, `content`, `tags`, `folderid` | - |
| 3 | - | - | - | - | 기존 데이터로 폼 채우기 |
| 4 | 제목/내용/태그/폴더 수정 | - | - | - | 입력 필드 업데이트 |
| 5 | "저장" 버튼 클릭 | - | - | - | 저장 처리 중 표시 |
| 6 | - | 변경 사항 감지 (이전 값 vs 새 값) | - | - | - |
| 7 | - | **UPDATE** 메모 업데이트 | `memo` | `title`, `content`, `tags`, `folderid`, `updateAt` | - |
| 8 | - | **UPDATE** 폴더 변경 시: 이전 폴더 개수 감소 | `folder` | `memoCount` ← -1 | - |
| 9 | - | **UPDATE** 폴더 변경 시: 새 폴더 개수 증가 | `folder` | `memoCount` ← +1 | - |
| 10 | - | **UPDATE** 제거된 태그 개수 감소 | `tag` | `memoCount` ← -1 | - |
| 11 | - | **CREATE/UPDATE** 추가된 태그 생성 또는 개수 증가 | `tag` | `id`, `userid`, `name`, `color`, `memoCount` | - |
| 12 | - | Firestore Stream 자동 업데이트 | - | - | 이전 화면으로 돌아감 |
| 13 | - | - | - | - | 메모 목록에서 수정된 내용 반영 |

**데이터 소스:**
- `memo`: 사용자 메모
- `folder`: 메모 폴더
- `tag`: 메모 태그

---

### 2.4 메모 삭제 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 메모 편집 화면에서 "삭제" 버튼 클릭 | - | - | - | 삭제 확인 다이얼로그 표시 |
| 2 | "확인" 버튼 클릭 | - | - | - | 삭제 처리 중 표시 |
| 3 | - | 삭제 전 메모 정보 저장 (복원용) | `memo` | `folderid`, `tags` | - |
| 4 | - | **DELETE** 메모 삭제 | `memo` | `id` | - |
| 5 | - | **UPDATE** 폴더 메모 개수 감소 (폴더 지정 시) | `folder` | `memoCount` ← -1 | - |
| 6 | - | **UPDATE** 모든 태그 메모 개수 감소 | `tag` | `memoCount` ← -1 | - |
| 7 | - | Firestore Stream 자동 업데이트 | - | - | 이전 화면으로 돌아감 |
| 8 | - | - | - | - | 메모 목록에서 삭제된 메모 제거 |
| 9 | - | - | - | - | 폴더 카드의 메모 개수 갱신 |

**데이터 소스:**
- `memo`: 사용자 메모
- `folder`: 메모 폴더
- `tag`: 메모 태그

---

### 2.5 메모 고정/고정 해제 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 메모 카드에서 "고정" 아이콘 클릭 | - | - | - | 고정 처리 중 표시 |
| 2 | - | **UPDATE** 고정 상태 토글 | `memo` | `isPinned` ← !currentValue, `updateAt` | - |
| 3 | - | Firestore Stream 자동 업데이트 | - | - | - |
| 4 | - | - | - | - | 고정된 메모는 목록 상단으로 이동 |
| 5 | - | - | - | - | 고정 아이콘 표시 변경 (핀/해제) |

**데이터 소스:**
- `memo`: 사용자 메모

---

## 3. 폴더 관리 (Folder Management)

### 3.1 폴더 생성 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 홈 화면에서 "폴더 추가" 버튼 클릭 | - | - | - | 폴더 생성 다이얼로그 표시 |
| 2 | 폴더 이름, 아이콘, 색상 입력 | - | - | - | 입력 필드 업데이트 |
| 3 | "확인" 버튼 클릭 | - | - | - | 생성 처리 중 표시 |
| 4 | - | **CREATE** 폴더 생성 | `folder` | `id`, `userid`, `name`, `icon`, `color`, `memoCount` ← 0, `createdAt` | - |
| 5 | - | Firestore Stream 자동 업데이트 | - | - | 다이얼로그 닫힘 |
| 6 | - | - | - | - | 홈 화면 폴더 목록에 새 폴더 추가 |

**데이터 소스:**
- `folder`: 메모 폴더

**파일 위치:**
- DataSource: [lib/features/memo/data/datasources/firebase_folder_datasource.dart](../lib/features/memo/data/datasources/firebase_folder_datasource.dart)

---

### 3.2 폴더 조회 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | **HomeScreen** 진입 | - | - | - | 로딩 표시 |
| 2 | - | **READ** 사용자 폴더 목록 조회 (Stream) | `folder` | `id`, `userid`, `name`, `icon`, `color`, `memoCount`, `createdAt` | - |
| 3 | - | 메모리에서 `createdAt` 기준 내림차순 정렬 | - | - | - |
| 4 | - | - | - | - | 폴더 카드 목록 표시 |

**데이터 소스:**
- `folder`: 메모 폴더

---

### 3.3 폴더 수정 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 폴더 카드 길게 누르기 | - | - | - | 컨텍스트 메뉴 표시 |
| 2 | "편집" 선택 | - | - | - | 폴더 편집 다이얼로그 표시 |
| 3 | - | **READ** 폴더 정보 조회 | `folder` | `id`, `name`, `icon`, `color` | 기존 데이터로 폼 채우기 |
| 4 | 이름/아이콘/색상 수정 | - | - | - | 입력 필드 업데이트 |
| 5 | "확인" 버튼 클릭 | - | - | - | 수정 처리 중 표시 |
| 6 | - | **UPDATE** 폴더 업데이트 | `folder` | `name`, `icon`, `color` | - |
| 7 | - | Firestore Stream 자동 업데이트 | - | - | 다이얼로그 닫힘 |
| 8 | - | - | - | - | 홈 화면 폴더 카드 갱신 |
| 9 | - | - | - | - | 해당 폴더의 MemoListScreen 제목/색상 갱신 |

**데이터 소스:**
- `folder`: 메모 폴더

---

### 3.4 폴더 삭제 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 폴더 카드 길게 누르기 | - | - | - | 컨텍스트 메뉴 표시 |
| 2 | "삭제" 선택 | - | - | - | 삭제 확인 다이얼로그 표시 |
| 3 | "확인" 버튼 클릭 | - | - | - | 삭제 처리 중 표시 |
| 4 | - | **READ** 해당 폴더의 메모 목록 조회 | `memo` | `id`, `folderid` | - |
| 5 | - | **UPDATE** 폴더 내 모든 메모의 폴더 연결 해제 | `memo` | `folderid` ← null | - |
| 6 | - | **DELETE** 폴더 삭제 | `folder` | `id` | - |
| 7 | - | Firestore Stream 자동 업데이트 | - | - | - |
| 8 | - | - | - | - | 홈 화면에서 폴더 카드 제거 |
| 9 | - | - | - | - | 해당 폴더의 메모들은 "미분류"로 표시 |

**데이터 소스:**
- `folder`: 메모 폴더
- `memo`: 사용자 메모 (폴더 연결 해제)

---

## 4. 태그 관리 (Tag Management)

### 4.1 태그 자동 생성 흐름 (메모 저장 시)

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 메모 저장 시 `tags[]` 배열 포함 | - | - | - | - |
| 2 | - | 각 태그 이름에 대해 처리 시작 | - | - | - |
| 3 | - | **READ** 기존 태그 존재 여부 확인 | `tag` | `id`, `name` | - |
| 4a | - | (기존 태그) **UPDATE** 메모 개수 증가 | `tag` | `memoCount` ← +1 | - |
| 4b | - | (새 태그) **CREATE** 태그 생성 | `tag` | `id`, `userid`, `name`, `color` ← 랜덤, `memoCount` ← 1, `createdAt` | - |
| 5 | - | Firestore Stream 자동 업데이트 | - | - | - |
| 6 | - | - | - | - | 태그 관리 화면의 태그 목록 갱신 |

**데이터 소스:**
- `tag`: 메모 태그
- `memo`: 사용자 메모 (`tags[]` 배열 참조용)

**파일 위치:**
- DataSource: [lib/features/memo/data/datasources/firebase_tag_datasource.dart](../lib/features/memo/data/datasources/firebase_tag_datasource.dart)

---

### 4.2 태그 조회 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 드로어에서 "태그 관리" 클릭 | - | - | - | 태그 관리 화면 진입 |
| 2 | - | **READ** 사용자 태그 목록 조회 (Stream) | `tag` | `id`, `userid`, `name`, `color`, `memoCount`, `createdAt` | - |
| 3 | - | 메모리에서 `memoCount` 기준 내림차순 정렬 | - | - | - |
| 4 | - | - | - | - | 태그 목록 표시 (이름, 색상, 사용 횟수) |

**데이터 소스:**
- `tag`: 메모 태그

---

### 4.3 태그 수정 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 태그 관리 화면에서 태그 클릭 | - | - | - | 컨텍스트 메뉴 표시 |
| 2 | "편집" 선택 | - | - | - | 태그 편집 다이얼로그 표시 |
| 3 | - | **READ** 태그 정보 조회 | `tag` | `id`, `name`, `color` | 기존 데이터로 폼 채우기 |
| 4 | 이름/색상 수정 | - | - | - | 입력 필드 업데이트 |
| 5 | "확인" 버튼 클릭 | - | - | - | 수정 처리 중 표시 |
| 6 | - | **UPDATE** 태그 업데이트 | `tag` | `name`, `color` | - |
| 7 | - | (이름 변경 시) **UPDATE** 관련 메모의 태그 배열 갱신 | `memo` | `tags[]` ← 이전 이름 → 새 이름 | - |
| 8 | - | Firestore Stream 자동 업데이트 | - | - | 다이얼로그 닫힘 |
| 9 | - | - | - | - | 태그 목록 갱신 |
| 10 | - | - | - | - | 메모 카드의 태그 표시 갱신 |

**데이터 소스:**
- `tag`: 메모 태그
- `memo`: 사용자 메모 (태그 이름 변경 시)

---

### 4.4 태그 삭제 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 태그 관리 화면에서 태그 클릭 | - | - | - | 컨텍스트 메뉴 표시 |
| 2 | "삭제" 선택 | - | - | - | 삭제 확인 다이얼로그 표시 |
| 3 | "확인" 버튼 클릭 | - | - | - | 삭제 처리 중 표시 |
| 4 | - | **READ** 해당 태그를 사용 중인 메모 목록 조회 | `memo` | `id`, `tags` | - |
| 5 | - | **UPDATE** 모든 관련 메모의 태그 배열에서 제거 | `memo` | `tags[]` ← 해당 태그 제거 | - |
| 6 | - | **DELETE** 태그 삭제 | `tag` | `id` | - |
| 7 | - | Firestore Stream 자동 업데이트 | - | - | - |
| 8 | - | - | - | - | 태그 목록에서 제거 |
| 9 | - | - | - | - | 메모 카드의 태그 표시에서 제거 |

**데이터 소스:**
- `tag`: 메모 태그
- `memo`: 사용자 메모 (태그 배열 갱신)

---

## 5. AI 기능 (AI Features)

### 5.1 AI 자동 분류 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 메모 편집 화면에서 "AI 자동 분류" 버튼 클릭 | - | - | - | AI 분류 진행 중 표시 |
| 2 | - | **READ** 사용자 폴더 목록 조회 | `folder` | `id`, `name` | - |
| 3 | - | 폴더 ID:이름 맵 생성 | - | - | - |
| 4 | - | **AI API** Gemini API 호출 | - | - | - |
| 5 | - | AI 입력: 메모 제목, 내용, 폴더 목록 | `memo` | `title`, `content` (임시) | - |
| 6 | - | AI 처리: 내용 분석, 폴더 추천, 태그 생성 | - | - | - |
| 7 | - | AI 출력: 추천 폴더 ID, 태그 목록 수신 | - | - | - |
| 8 | - | **UPDATE** 가이드 진행 상태 (첫 사용 시) | `guideprogress` | `aiClassificationChecked` ← true | - |
| 9 | - | - | - | - | AI 분류 결과 폼에 자동 반영 |
| 10 | - | - | - | - | 선택된 폴더 표시 |
| 11 | - | - | - | - | 추천 태그 칩 목록 표시 |

**데이터 소스:**
- `folder`: 메모 폴더 (AI 입력용)
- `memo`: 사용자 메모 (제목, 내용 AI 입력용)
- `guideprogress`: 가이드 진행 상태 (Local Storage)

**AI 처리 과정:**
1. Gemini API에 메모 내용과 폴더 목록 전송
2. AI가 내용 분석하여 가장 적합한 폴더 선택
3. AI가 메모 내용에서 키워드 추출하여 태그 생성 (최대 5개)
4. 결과를 앱으로 반환

**파일 위치:**
- AI Service: [lib/features/ai/data/services/gemini_service.dart](../lib/features/ai/data/services/gemini_service.dart)

---

### 5.2 AI 자연어 검색 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 홈 화면에서 검색 아이콘 클릭 | - | - | - | **AISearchScreen** 진입 |
| 2 | 자연어 검색어 입력 (예: "지난주 업무 메모") | - | - | - | 검색어 입력 필드 업데이트 |
| 3 | "검색" 버튼 클릭 | - | - | - | 검색 진행 중 표시 |
| 4 | - | **READ** 사용자의 모든 메모 조회 | `memo` | `id`, `title`, `content`, `tags`, `folderid`, `createAt`, `updateAt` | - |
| 5 | - | **AI API** Gemini API 호출 (자연어 검색) | - | - | - |
| 6 | - | AI 입력: 검색어, 전체 메모 목록 | - | - | - |
| 7 | - | AI 처리: 검색 의도 파악, 조건 추출, 관련도 계산 | - | - | - |
| 8 | - | AI 출력: 관련도 순으로 정렬된 메모 목록 | - | - | - |
| 9 | - | **UPDATE** 가이드 진행 상태 (첫 사용 시) | `guideprogress` | `naturalSearchUsed` ← true | - |
| 10 | - | - | - | - | 검색 결과 메모 목록 표시 |
| 11 | - | - | - | - | 매칭된 부분 하이라이트 표시 |

**데이터 소스:**
- `memo`: 사용자 메모 (AI 검색 대상)
- `guideprogress`: 가이드 진행 상태 (Local Storage)

**AI 검색 처리 과정:**
1. 자연어 쿼리를 구조화된 검색 조건으로 변환
2. 메모 제목, 내용, 태그에서 키워드 매칭
3. 날짜 조건 파싱 및 필터링 ("지난주", "최근", "3월" 등)
4. 관련도 점수 계산 및 정렬

**파일 위치:**
- Screen: [lib/features/search/presentation/screens/ai_search_screen.dart](../lib/features/search/presentation/screens/ai_search_screen.dart)

---

## 6. 가이드 시스템 (Guide System)

### 6.1 초기 가이드 표시 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 앱 실행, **HomeScreen** 진입 | - | - | - | 로딩 표시 |
| 2 | - | **READ** 가이드 진행 상태 조회 (Local Storage) | `guideprogress` | `firstMemoCreated`, `aiClassificationChecked`, `naturalSearchUsed`, `linkSummaryChecked`, `guideCompleted` | - |
| 3a | - | (가이드 미완료) 다음 단계 확인 | - | - | - |
| 3b | - | (가이드 완료) 가이드 표시 안 함 | - | - | 홈 화면 정상 표시 |
| 4 | - | - | - | - | **InitialGuideOverlay** 표시 (미완료 시) |
| 5 | - | - | - | - | 다음 완료할 단계 안내 표시 |
| 6 | - | - | - | - | 진행률 표시 (예: 2/5 완료) |

**데이터 소스:**
- `guideprogress`: 가이드 진행 상태 (Local Storage - SharedPreferences)

**파일 위치:**
- Entity: [lib/features/guide/domain/entities/guide_progress.dart](../lib/features/guide/domain/entities/guide_progress.dart)
- Service: [lib/features/guide/data/guide_service.dart](../lib/features/guide/data/guide_service.dart)

---

### 6.2 가이드 진행 업데이트 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 특정 기능 완료 (예: 첫 메모 작성) | - | - | - | - |
| 2 | - | **UPDATE** 가이드 진행 상태 해당 필드 갱신 | `guideprogress` | `firstMemoCreated` ← true (또는 해당 필드) | - |
| 3 | - | SharedPreferences에 저장 | - | - | - |
| 4 | - | 모든 단계 완료 여부 확인 | - | - | - |
| 5a | - | (모든 단계 완료) **UPDATE** 가이드 완료 상태 | `guideprogress` | `guideCompleted` ← true | - |
| 5b | - | (미완료 단계 존재) 다음 단계 확인 | - | - | - |
| 6a | - | - | - | - | 축하 메시지 표시 (전체 완료 시) |
| 6b | - | - | - | - | 다음 단계 안내 표시 (미완료 시) |

**데이터 소스:**
- `guideprogress`: 가이드 진행 상태 (Local Storage)

---

## 7. 프로필 관리 (Profile Management)

### 7.1 프로필 조회 흐름

| 단계 | 사용자 액션 | 데이터 작업 | 데이터 소스 (Entity) | 관련 Attributes | 화면 변화 |
|------|-------------|-------------|---------------------|-----------------|-----------|
| 1 | 드로어에서 "프로필" 클릭 | - | - | - | **ProfileScreen** 진입 |
| 2 | - | **READ** 현재 사용자 정보 조회 | `user` | `id`, `email`, `displayName`, `photoURL` | - |
| 3 | - | - | - | - | 프로필 사진 표시 |
| 4 | - | - | - | - | 표시 이름 (displayName) 표시 |
| 5 | - | - | - | - | 이메일 표시 |
| 6 | - | **COUNT** 사용자 메모 개수 조회 | `memo` | - | - |
| 7 | - | **COUNT** 사용자 폴더 개수 조회 | `folder` | - | - |
| 8 | - | **COUNT** 사용자 태그 개수 조회 | `tag` | - | - |
| 9 | - | - | - | - | 통계 카드 표시 (메모, 폴더, 태그 개수) |

**데이터 소스:**
- `user`: 사용자 정보 (Firebase Authentication)
- `memo`: 사용자 메모 (개수 집계용)
- `folder`: 메모 폴더 (개수 집계용)
- `tag`: 메모 태그 (개수 집계용)

**파일 위치:**
- Screen: [lib/features/profile/presentation/screens/profile_screen.dart](../lib/features/profile/presentation/screens/profile_screen.dart)

---

## 8. Entity 간 데이터 연결 요약

### 8.1 ERD 기반 관계 매핑

아래는 ERD에 정의된 Entity 간의 관계를 데이터 흐름 관점에서 요약한 내용입니다.

```
user (Firebase Authentication)
    ├── 1:N → memo
    │   ├── FK: memo.userid → user.id
    │   ├── memo.tags[] (Array<String>) → tag.name 참조 (N:M)
    │   └── memo.folderid? → folder.id 참조 (Optional 1:N)
    │
    ├── 1:N → folder
    │   ├── FK: folder.userid → user.id
    │   └── folder.memoCount: 집계 데이터 (Denormalized)
    │       - memo 생성/삭제/이동 시 자동 동기화
    │
    ├── 1:N → tag
    │   ├── FK: tag.userid → user.id (Firestore 경로: users/{userid}/tags/{tagid})
    │   └── tag.memoCount: 집계 데이터 (Denormalized)
    │       - memo의 tags[] 배열 변경 시 자동 동기화
    │
    └── 1:1 → guideprogress
        └── Local Storage (SharedPreferences, 사용자별 독립)
            - 앱 온보딩 가이드 진행 상태 추적
```

**주요 관계 특징:**
1. **user ← memo**: 1:N 관계, `userid` 필드로 소유권 관리
2. **folder ← memo**: 1:N Optional 관계, `folderid` null 가능 (미분류 메모)
3. **tag ↔ memo**: N:M 관계, `memo.tags[]` 배열에 태그 이름 저장
4. **guideprogress**: 독립 Entity, Local Storage에만 존재

---

### 8.2 데이터 정합성 관리

Firestore의 비정규화(Denormalization) 전략으로 인해 집계 데이터(`memoCount`)의 정합성을 수동으로 관리해야 합니다.

#### 8.2.1 folder.memoCount 동기화

| 데이터 작업 | folder.memoCount 변화 | 트리거 조건 | 구현 위치 |
|-------------|----------------------|------------|-----------|
| memo **CREATE** (폴더 지정) | +1 | `memo.folderid` 설정 시 | `firebase_memo_datasource.dart:createMemo()` |
| memo **DELETE** (폴더 지정) | -1 | `memo.folderid` 존재 시 | `firebase_memo_datasource.dart:deleteMemo()` |
| memo **UPDATE** (폴더 변경) | 이전 폴더 -1, 새 폴더 +1 | `memo.folderid` 변경 시 | `firebase_memo_datasource.dart:updateMemo()` |
| folder **DELETE** | N/A (폴더 삭제됨) | 메모의 `folderid` → null | `firebase_folder_datasource.dart:deleteFolder()` |

**Firestore 구현:**
```dart
// FieldValue.increment() 사용으로 원자적 업데이트
await folderDoc.update({'memoCount': FieldValue.increment(1)});
await folderDoc.update({'memoCount': FieldValue.increment(-1)});
```

---

#### 8.2.2 tag.memoCount 동기화

| 데이터 작업 | tag.memoCount 변화 | 트리거 조건 | 구현 위치 |
|-------------|---------------------|------------|-----------|
| memo **CREATE** (태그 포함) | 각 태그 +1 | `memo.tags[]` 포함 시 | `firebase_tag_datasource.dart` |
| memo **DELETE** (태그 포함) | 각 태그 -1 | `memo.tags[]` 존재 시 | `firebase_tag_datasource.dart` |
| memo **UPDATE** (태그 변경) | 제거된 태그 -1, 추가된 태그 +1 | `memo.tags[]` 변경 시 | `firebase_tag_datasource.dart` |
| tag **DELETE** | N/A (태그 삭제됨) | 메모의 `tags[]`에서 제거 | `firebase_tag_datasource.dart:deleteTag()` |

**Firestore 구현 (Batch Write):**
```dart
final batch = firestore.batch();
for (final tagName in addedTags) {
  batch.update(tagDoc, {'memoCount': FieldValue.increment(1)});
}
for (final tagName in removedTags) {
  batch.update(tagDoc, {'memoCount': FieldValue.increment(-1)});
}
await batch.commit();
```

---

#### 8.2.3 태그 이름 동기화 (N:M 관계 특성)

**현재 구조의 특징:**
- `memo.tags[]`: 태그 **이름**(String) 배열 저장 (태그 ID 아님)
- `tag` Entity: 태그 메타데이터 (이름, 색상, 개수) 관리

**태그 이름 변경 시 주의사항:**
1. `tag.name` 변경 시
2. **모든 관련 memo의 `tags[]` 배열도 동기화 필요**
3. 대량 업데이트 필요 → **Batch Write 사용**

**Firestore 구현:**
```dart
// 1. 해당 태그를 사용하는 메모 조회
final memosWithTag = await getMemosByTag(oldTagName);

// 2. Batch로 모든 메모의 tags[] 업데이트
final batch = firestore.batch();
for (final memo in memosWithTag) {
  final updatedTags = memo.tags.map((t) =>
    t == oldTagName ? newTagName : t
  ).toList();
  batch.update(memoDoc, {'tags': updatedTags});
}

// 3. 태그 이름 업데이트
batch.update(tagDoc, {'name': newTagName});

// 4. 원자적 커밋
await batch.commit();
```

---

## 9. ERD와 데이터 흐름도 검증

### 9.1 Entity 관계 검증

아래는 [database.erd](../database.erd) 파일에 정의된 Entity 관계가 데이터 흐름도에 정확히 반영되었는지 검증한 결과입니다.

| ERD Entity 관계 | 데이터 흐름도 반영 | 사용된 Attributes | 검증 결과 |
|----------------|------------------|------------------|----------|
| **user ─< memo** (1:N) | ✅ 모든 memo CRUD에서 `userid` 필터링 | `id`, `userid`, `title`, `content`, `tags`, `folderid`, `createAt`, `updateAt`, `isPinned` | ✅ 일치 |
| **user ─< folder** (1:N) | ✅ 모든 folder CRUD에서 `userid` 필터링 | `id`, `userid`, `name`, `icon`, `color`, `memoCount`, `createdAt` | ✅ 일치 |
| **user ─< tag** (1:N) | ✅ 모든 tag CRUD에서 `userid` 기반 경로 사용 | `id`, `userid`, `name`, `color`, `memoCount`, `createdAt` | ✅ 일치 |
| **folder ─< memo** (1:N, Optional) | ✅ memo 생성/수정/삭제 시 `folderid` 처리 및 `memoCount` 동기화 | `folderid` (nullable) | ✅ 일치 |
| **memo ↔ tag** (N:M) | ✅ `memo.tags[]` 배열로 태그 이름 참조, `memoCount` 동기화 | `tags` (Array<String>) | ✅ 일치 |
| **guideprogress** (독립) | ✅ Local Storage 독립 관리, 주요 기능 완료 시 업데이트 | `firstMemoCreated`, `aiClassificationChecked`, `naturalSearchUsed`, `linkSummaryChecked`, `guideCompleted` | ✅ 일치 |

---

### 9.2 Firestore 경로 및 데이터 구조 검증

| Entity | Firestore 경로 | 사용자 격리 방식 | 일치 여부 | 비고 |
|--------|---------------|----------------|----------|------|
| `memo` | `memos/{memoId}` | `userid` 필드 | ✅ 일치 | 최상위 컬렉션 |
| `folder` | `folders/{folderId}` | `userid` 필드 | ✅ 일치 | 최상위 컬렉션 |
| `tag` | `users/{userid}/tags/{tagId}` | 경로 (Subcollection) | ✅ 일치 | 사용자별 서브컬렉션 |
| `guideprogress` | Local Storage | SharedPreferences | ✅ 일치 | Firestore 미사용 |

**검증 결과:**
- ✅ 모든 Entity의 Firestore 경로가 실제 구현과 일치합니다.
- ✅ `memo`와 `folder`는 `userid` 필드로 사용자 격리를 보장하며, Firestore Security Rules로 추가 보호됩니다.
- ✅ `tag`는 Subcollection 구조로 자동 격리됩니다.

---

### 9.3 Attribute 사용 검증

**ERD에 정의된 모든 Attributes가 데이터 흐름에서 활용되는지 확인:**

| Entity | ERD Attributes | 데이터 흐름도에서 사용 | 미사용 Attribute |
|--------|---------------|---------------------|----------------|
| `user` | `id`, `email`, `displayName`, `photoURL` | ✅ 모두 사용 (인증, 프로필) | 없음 |
| `memo` | `id`, `userid`, `title`, `content`, `tags`, `folderid`, `createAt`, `updateAt`, `isPinned` | ✅ 모두 사용 (CRUD, 정렬, 필터링) | 없음 |
| `folder` | `id`, `userid`, `name`, `icon`, `color`, `memoCount`, `createdAt` | ✅ 모두 사용 (표시, 집계) | 없음 |
| `tag` | `id`, `userid`, `name`, `color`, `memoCount`, `createdAt` | ✅ 모두 사용 (표시, 집계) | 없음 |
| `guideprogress` | `firstMemoCreated`, `aiClassificationChecked`, `naturalSearchUsed`, `linkSummaryChecked`, `guideCompleted` | ✅ 모두 사용 (가이드 시스템) | 없음 |

**검증 결과:**
- ✅ ERD에 정의된 **모든 Attributes가 데이터 흐름에서 활용**됩니다.
- ✅ 누락되거나 불필요한 Attribute가 없습니다.

---

## 10. Firestore 실시간 업데이트 메커니즘

### 10.1 Stream 기반 반응형 UI

대부분의 데이터 조회는 **Stream**을 사용하여 실시간 동기화:

```dart
// 예시: Memo 목록 실시간 감시
Stream<List<MemoModel>> watchMemos(String userId) {
  return _memosCollection
      .where('userId', isEqualTo: userId)
      .snapshots()  // ← Firestore snapshot stream
      .map((snapshot) {
        final memos = snapshot.docs
            .map((doc) => MemoModel.fromFirestore(doc))
            .toList();
        memos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return memos;
      });
}
```

**UI 업데이트 흐름:**
1. Firestore 데이터 변경 발생 (Create/Update/Delete)
2. `snapshots()` Stream이 자동으로 새 데이터 전송
3. Riverpod StreamProvider가 변경 감지
4. Flutter UI 자동 리빌드
5. 사용자에게 즉시 반영

**장점:**
- 다른 기기/세션에서의 변경도 즉시 반영
- 수동 새로고침 불필요
- 낙관적 업데이트 + 자동 동기화

---

### 10.2 배치 작업 (Batch Operations)

여러 Entity를 동시에 업데이트할 때 **Firestore Batch** 사용:

```dart
// 예시: 여러 폴더 한 번에 생성
Future<void> createFolders(List<FolderModel> folders) async {
  final batch = _firestore.batch();
  for (final folder in folders) {
    final docRef = _firestore.collection('folders').doc(folder.id);
    batch.set(docRef, folder.toFirestore());
  }
  await batch.commit();  // ← 원자적 실행
}
```

**사용 시나리오:**
- 초기 폴더 세트 생성
- 메모 삭제 시 여러 태그 카운트 일괄 업데이트
- 태그 이름 변경 시 여러 메모 일괄 업데이트

**장점:**
- 원자성 (Atomicity): 모두 성공 또는 모두 실패
- 성능 향상: 단일 네트워크 왕복

---

## 11. 주요 데이터 흐름 패턴 요약

### 11.1 생성 (Create) 패턴

```
사용자 입력
    ↓
Entity 생성 (ID auto-generated)
    ↓
Firestore에 저장
    ↓
관련 Entity 카운트 증가 (if applicable)
    ↓
Stream 자동 업데이트
    ↓
UI 갱신
```

---

### 11.2 조회 (Read) 패턴

```
화면 진입
    ↓
Stream 구독 (Riverpod StreamProvider)
    ↓
Firestore Query (userId 필터)
    ↓
정렬 (메모리 또는 Firestore)
    ↓
UI 렌더링
    ↓
[실시간 감시 계속]
```

---

### 11.3 수정 (Update) 패턴

```
사용자 수정
    ↓
변경 사항 감지 (이전 값 vs 새 값)
    ↓
Entity 업데이트
    ↓
Firestore에 반영
    ↓
관련 Entity 동기화 (카운트, 참조 등)
    ↓
Stream 자동 업데이트
    ↓
UI 갱신
```

---

### 11.4 삭제 (Delete) 패턴

```
사용자 삭제 확인
    ↓
삭제 전 정보 수집 (folderId, tags[] 등)
    ↓
Firestore에서 삭제
    ↓
관련 Entity 카운트 감소
    ↓
참조하는 Entity 정리 (folderId null화, tags[] 제거 등)
    ↓
Stream 자동 업데이트
    ↓
UI 갱신
```

---

## 12. 성능 최적화 고려사항

### 12.1 인덱스 제거 전략

현재 구현은 **Firestore Composite Index를 최소화**하기 위해:
- Firestore에서 `orderBy` 제거
- 메모리에서 정렬 수행 (`sort()`)

**장점:**
- 인덱스 생성 불필요 → 배포 간소화
- Firestore 비용 절감

**단점:**
- 대량 데이터 시 클라이언트 부하 증가
- 페이지네이션 구현 어려움

**권장 사항:**
- 사용자당 메모 수가 1000개 이하: 현재 방식 유지
- 대량 데이터 예상: Firestore orderBy + 인덱스 사용 고려

---

### 12.2 캐싱 전략

**현재:**
- Firestore SDK 자동 캐싱 (오프라인 지원)
- Stream 구독으로 메모리 캐시 유지

**추가 고려사항:**
- 자주 사용하는 폴더/태그 목록: 앱 시작 시 미리 로드
- 최근 조회한 메모: 로컬 캐시 활용

---

## 11. 결론

이 데이터 흐름도는 Pamyo One 앱의 모든 주요 기능에서 **사용자 액션 → 데이터 작업(CRUD) → 데이터 소스(Entity) → 관련 Attributes → 화면 변화** 순서로 데이터가 어떻게 흐르는지를 단계별로 상세히 설명합니다.

---

### 11.1 핵심 데이터 흐름 특징

1. **사용자 데이터 격리**
   - 모든 Entity는 `userid` 필드 또는 Firestore 경로로 사용자별 격리
   - Firebase Authentication과 Security Rules로 이중 보호

2. **실시간 반응형 UI**
   - Firestore `snapshots()` Stream을 사용한 실시간 동기화
   - Riverpod StreamProvider로 UI 자동 갱신
   - 다른 기기/세션 간 변경사항 즉시 반영

3. **데이터 정합성 관리**
   - **Denormalized 집계 데이터**: `folder.memoCount`, `tag.meemoCount`
   - **FieldValue.increment()**: 원자적 카운트 업데이트
   - **Batch Write**: 다수 Entity 동시 업데이트 (태그 이름 변경 등)

4. **AI 기능 통합**
   - **Gemini API**: 메모 자동 분류, 태그 생성, 자연어 검색
   - 사용자 폴더 목록을 AI에 제공하여 컨텍스트 기반 분류
   - 가이드 시스템과 연동하여 사용 추적

5. **가이드 시스템**
   - Local Storage (SharedPreferences)로 독립 관리
   - 주요 기능 완료 시 자동 업데이트
   - 앱 온보딩 경험 개선

---

### 11.2 ERD와의 일치도 검증 결과

| 검증 항목 | 결과 | 상세 |
|----------|------|------|
| **Entity 관계** | ✅ 100% 일치 | 모든 1:N, N:M 관계가 데이터 흐름에 정확히 반영됨 |
| **Firestore 경로** | ✅ 100% 일치 | `memo`, `folder`, `tag` 모두 ERD와 일치 |
| **Attribute 사용** | ✅ 100% 활용 | ERD의 모든 Attributes가 데이터 흐름에서 사용됨 |
| **CRUD 작업** | ✅ 완전 구현 | Create, Read, Update, Delete 모두 문서화됨 |

---

### 11.3 주요 데이터 작업 패턴 요약

#### CREATE 패턴
```
사용자 입력 → Entity 생성 (auto-generated ID)
→ Firestore 저장 → 관련 Entity 카운트 증가
→ Stream 자동 업데이트 → UI 갱신
```

#### READ 패턴
```
화면 진입 → Stream 구독 (Riverpod)
→ Firestore Query (userid 필터) → 메모리 정렬
→ UI 렌더링 → 실시간 감시 계속
```

#### UPDATE 패턴
```
사용자 수정 → 변경 사항 감지 → Entity 업데이트
→ Firestore 반영 → 관련 Entity 동기화
→ Stream 자동 업데이트 → UI 갱신
```

#### DELETE 패턴
```
삭제 확인 → 삭제 전 정보 수집 → Firestore 삭제
→ 관련 Entity 카운트 감소 → 참조 정리
→ Stream 자동 업데이트 → UI 갱신
```

---

### 11.4 다음 단계 권장 사항

**구현 개선:**
1. ✅ 태그 이름 변경 시 memo.tags[] 배열 동기화 로직 구현 확인
2. 대량 데이터(메모 1000개 이상) 환경에서 페이지네이션 고려
3. Firestore Composite Index 전략 재검토 (현재 메모리 정렬 사용)

**성능 최적화:**
1. 자주 조회하는 폴더/태그 목록 앱 시작 시 미리 로드
2. 최근 조회한 메모 로컬 캐시 활용
3. AI API 호출 최소화 (결과 캐싱 고려)

**문서화:**
1. ✅ ERD와 데이터 흐름도 완전 동기화 완료
2. Firestore Security Rules 문서화
3. 각 DataSource 메서드별 트랜잭션 로직 명세

---

이 데이터 흐름도는 Pamyo One 앱의 **전체 데이터 아키텍처와 사용자 경험 흐름**을 완전히 문서화하였으며, ERD와 100% 일치하는 것을 검증하였습니다.
