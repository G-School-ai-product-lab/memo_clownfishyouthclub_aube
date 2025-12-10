# Pamyo One - ERD (Entity Relationship Diagram)

## 개요
Pamyo One은 메모 관리 앱으로, 사용자가 메모를 작성하고 폴더와 태그로 분류할 수 있는 시스템입니다.

## Entity 목록

### 1. User (사용자)
Firebase Authentication을 통해 관리되는 사용자 정보

**Attributes:**
- `id` (String, PK): Firebase Auth UID
- `email` (String): 사용자 이메일
- `displayName` (String?): 사용자 표시 이름
- `photoURL` (String?): 프로필 사진 URL

---

### 2. Memo (메모)
사용자가 작성한 메모

**Attributes:**
- `id` (String, PK): 메모 고유 ID
- `userId` (String, FK): 메모 작성자 ID
- `title` (String): 메모 제목
- `content` (String): 메모 내용
- `tags` (List<String>): 태그 이름 목록
- `folderId` (String?, FK): 소속 폴더 ID (nullable)
- `createdAt` (DateTime): 생성 일시
- `updatedAt` (DateTime): 수정 일시
- `isPinned` (bool): 고정 여부 (default: false)

**Firestore Path:** `memos/{memoId}`

---

### 3. Folder (폴더)
메모를 그룹화하는 폴더

**Attributes:**
- `id` (String, PK): 폴더 고유 ID
- `userId` (String, FK): 폴더 소유자 ID
- `name` (String): 폴더 이름
- `icon` (String): 폴더 아이콘 (default: '📁')
- `color` (String): 폴더 색상 (default: 'blue')
- `memoCount` (int): 폴더 내 메모 개수 (default: 0)
- `createdAt` (DateTime): 생성 일시

**Firestore Path:** `folders/{folderId}`
**Note:** 사용자 격리는 `userId` 필드로 관리

---

### 4. Tag (태그)
메모에 붙일 수 있는 태그

**Attributes:**
- `id` (String, PK): 태그 고유 ID
- `userId` (String, FK): 태그 소유자 ID
- `name` (String): 태그 이름
- `color` (String): 태그 색상 (default: 'purple')
- `memoCount` (int): 태그가 사용된 메모 개수 (default: 0)
- `createdAt` (DateTime): 생성 일시

**Firestore Path:** `users/{userId}/tags/{tagId}`

---

### 5. GuideProgress (가이드 진행 상황)
사용자의 앱 사용 가이드 완료 상황

**Attributes:**
- `firstMemoCreated` (bool): 첫 메모 작성 여부 (default: false)
- `aiClassificationChecked` (bool): AI 분류 확인 여부 (default: false)
- `naturalSearchUsed` (bool): 자연어 검색 사용 여부 (default: false)
- `linkSummaryChecked` (bool): 링크 요약 확인 여부 (default: false)
- `guideCompleted` (bool): 가이드 완료 여부 (default: false)

**Note:** Local storage로 관리되며, 별도의 ID가 없음

---

## Entity Relationships

### ERD 다이어그램

```
┌─────────────────────────────────────────────────────────────────────┐
│                              User                                   │
│                    (Firebase Authentication)                        │
│  ─────────────────────────────────────────────────────────────────  │
│  PK: id (String)                                                    │
│      email (String)                                                 │
│      displayName (String?)                                          │
│      photoURL (String?)                                             │
└───────────────┬─────────────────┬─────────────────┬─────────────────┘
                │                 │                 │
                │ 1               │ 1               │ 1
                │                 │                 │
                │                 │                 │
                │ N               │ N               │ N
       ┌────────▼────────┐ ┌──────▼──────┐ ┌───────▼────────┐
       │     Memo        │ │   Folder    │ │      Tag       │
       │ ─────────────── │ │ ─────────── │ │ ────────────── │
       │ PK: id          │ │ PK: id      │ │ PK: id         │
       │ FK: userId      │ │ FK: userId  │ │ FK: userId     │
       │ FK: folderId?   │ │ name        │ │ name           │
       │ title           │ │ icon        │ │ color          │
       │ content         │ │ color       │ │ memoCount      │
       │ tags[]          │ │ memoCount   │ │ createdAt      │
       │ createdAt       │ │ createdAt   │ └────────────────┘
       │ updatedAt       │ └─────────────┘          │
       │ isPinned        │        │                 │
       └─────────────────┘        │ 1               │
                │                 │                 │
                │ N               │                 │
                │                 │                 │
                └─────────────────┘                 │
                                                    │
                        ┌───────────────────────────┘
                        │ N:M (through tags[] array)
                        │
                        └─────────────────┐
                                          │
                                    [Tag Names]
                                    Memo.tags[]


┌─────────────────────────────────────────────────────────────────────┐
│                        GuideProgress                                │
│                       (Local Storage)                               │
│  ─────────────────────────────────────────────────────────────────  │
│  firstMemoCreated (bool)                                            │
│  aiClassificationChecked (bool)                                     │
│  naturalSearchUsed (bool)                                           │
│  linkSummaryChecked (bool)                                          │
│  guideCompleted (bool)                                              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 관계 상세 설명

### 1. User ─< Memo (1:N)
- 한 명의 사용자는 여러 개의 메모를 작성할 수 있습니다.
- 메모는 반드시 한 명의 사용자에게 속합니다.
- **관계 타입:** 1:N (One-to-Many)
- **FK:** `Memo.userId` → `User.id`

### 2. User ─< Folder (1:N)
- 한 명의 사용자는 여러 개의 폴더를 생성할 수 있습니다.
- 폴더는 반드시 한 명의 사용자에게 속합니다.
- **관계 타입:** 1:N (One-to-Many)
- **FK:** `Folder.userId` → `User.id`

### 3. User ─< Tag (1:N)
- 한 명의 사용자는 여러 개의 태그를 생성할 수 있습니다.
- 태그는 반드시 한 명의 사용자에게 속합니다.
- **관계 타입:** 1:N (One-to-Many)
- **FK:** `Tag.userId` → `User.id`

### 4. Folder ─< Memo (1:N, Optional)
- 한 개의 폴더는 여러 개의 메모를 포함할 수 있습니다.
- 메모는 선택적으로 한 개의 폴더에 속할 수 있습니다 (nullable).
- 폴더가 없는 메모도 존재할 수 있습니다.
- **관계 타입:** 1:N (One-to-Many, Optional)
- **FK:** `Memo.folderId` → `Folder.id` (nullable)

### 5. Memo >─< Tag (N:M)
- 한 개의 메모는 여러 개의 태그를 가질 수 있습니다.
- 한 개의 태그는 여러 개의 메모에 사용될 수 있습니다.
- **관계 타입:** N:M (Many-to-Many)
- **구현 방식:**
  - `Memo.tags` 배열에 태그 이름(String)을 저장
  - 별도의 중간 테이블 없이 배열로 관계 관리
  - `Tag.memoCount`로 사용 횟수 집계

### 6. GuideProgress (독립 Entity)
- 사용자와 논리적으로 연결되지만, Local Storage에 저장되어 Firebase와 독립적입니다.
- 사용자별 가이드 진행 상황을 추적합니다.

---

## Firestore 데이터 구조

```
firestore/
├── memos/                          # 전체 메모 컬렉션
│   └── {memoId}/                   # 개별 메모 문서
│       ├── userId: string
│       ├── title: string
│       ├── content: string
│       ├── tags: string[]
│       ├── folderId?: string
│       ├── createdAt: timestamp
│       ├── updatedAt: timestamp
│       └── isPinned: boolean
│
├── folders/                        # 전체 폴더 컬렉션
│   └── {folderId}/                 # 개별 폴더 문서
│       ├── userId: string          # 사용자 격리용
│       ├── name: string
│       ├── icon: string
│       ├── color: string
│       ├── memoCount: number
│       └── createdAt: timestamp
│
└── users/                          # 사용자별 서브컬렉션
    └── {userId}/
        └── tags/                   # 태그 컬렉션
            └── {tagId}/            # 개별 태그 문서
                ├── userId: string
                ├── name: string
                ├── color: string
                ├── memoCount: number
                └── createdAt: timestamp
```

---

## 주요 특징

### 1. 사용자 격리 (User Isolation)
- 모든 데이터는 `userId`로 사용자별로 격리됩니다.
- Memo와 Folder는 최상위 컬렉션에 저장되며 `userId` 필드로 격리됩니다.
- Tag는 `users/{userId}/tags/` 하위에 저장되어 경로로 격리됩니다.

### 2. 비정규화 (Denormalization)
- `Folder.memoCount`와 `Tag.memoCount`는 집계 데이터입니다.
- 성능 향상을 위해 카운트를 미리 계산하여 저장합니다.

### 3. 태그 관계 구현
- N:M 관계를 별도의 중간 테이블 없이 배열(`Memo.tags[]`)로 구현합니다.
- 태그 이름을 직접 저장하여 조회 성능을 최적화합니다.
- `Tag` 엔티티는 태그의 메타데이터(색상, 카운트)를 관리합니다.

### 4. 선택적 폴더 분류
- 메모는 폴더 없이도 존재할 수 있습니다 (`folderId` nullable).
- 유연한 메모 관리가 가능합니다.

---

## 데이터 정합성 관리

### 카운트 업데이트
- 메모 추가/삭제 시 `Folder.memoCount` 증감
- 태그 추가/삭제 시 `Tag.memoCount` 증감
- Firestore의 `FieldValue.increment()` 사용

### 태그 동기화
- 메모 저장 시 `Memo.tags` 배열에 태그 이름 저장
- 새로운 태그는 자동으로 `Tag` 컬렉션에 생성
- 태그 삭제 시 관련 메모의 `tags` 배열도 업데이트 필요

---

## 참고 파일

### Entity 정의
- [Memo Entity](../lib/features/memo/domain/entities/memo.dart)
- [Folder Entity](../lib/features/memo/domain/entities/folder.dart)
- [Tag Entity](../lib/features/memo/domain/entities/tag.dart)
- [GuideProgress Entity](../lib/features/guide/domain/entities/guide_progress.dart)

### Model 구현
- [MemoModel](../lib/features/memo/data/models/memo_model.dart)
- [FolderModel](../lib/features/memo/data/models/folder_model.dart)
- [TagModel](../lib/features/memo/data/models/tag_model.dart)

### Datasource 구현
- [FirebaseMemoDataSource](../lib/features/memo/data/datasources/firebase_memo_datasource.dart)
- [FirebaseFolderDataSource](../lib/features/memo/data/datasources/firebase_folder_datasource.dart)
- [FirebaseTagDataSource](../lib/features/memo/data/datasources/firebase_tag_datasource.dart)

### 인증
- [AuthService](../lib/features/auth/data/services/auth_service.dart)
