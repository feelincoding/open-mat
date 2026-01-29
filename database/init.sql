-- ============================================
-- 주짓수 커뮤니티 MVP 데이터베이스 스키마
-- ============================================

-- ============================================
-- 1. users (회원)
-- ============================================
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    
    -- 이름
    real_name VARCHAR(100) NOT NULL,
    nickname VARCHAR(100) NOT NULL,
    is_real_name_public BOOLEAN NOT NULL DEFAULT false,
    
    -- 현재 소속
    gym_name VARCHAR(200),
    gym_place_id VARCHAR(100),
    instructor_name VARCHAR(100),
    belt_level VARCHAR(20),
    
    -- 권한
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    
    -- 타임스탬프
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP,
    
    CONSTRAINT chk_belt_level 
        CHECK (belt_level IN ('WHITE', 'BLUE', 'PURPLE', 'BROWN', 'BLACK')),
    CONSTRAINT chk_role
        CHECK (role IN ('USER', 'ADMIN'))
);

CREATE INDEX idx_users_real_name ON users(real_name);
CREATE INDEX idx_users_gym_place_id ON users(gym_place_id) 
    WHERE gym_place_id IS NOT NULL;
CREATE INDEX idx_users_deleted_at ON users(deleted_at) 
    WHERE deleted_at IS NULL;

-- ============================================
-- 2. posts (게시글)
-- ============================================
CREATE TABLE posts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    
    -- 게시판 구분
    board_type VARCHAR(20) NOT NULL,
    
    -- 내용
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    
    -- 닉네임 공개 여부
    nickname_public BOOLEAN NOT NULL DEFAULT false,
    
    -- 통계
    view_count INT NOT NULL DEFAULT 0,
    like_count INT NOT NULL DEFAULT 0,
    comment_count INT NOT NULL DEFAULT 0,
    
    -- 타임스탬프
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id),
    
    CONSTRAINT chk_board_type 
        CHECK (board_type IN ('FREE', 'TECH', 'REVIEW'))
);

CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_board_type ON posts(board_type);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_deleted_at ON posts(deleted_at) 
    WHERE deleted_at IS NULL;

-- ============================================
-- 3. comments (댓글)
-- ============================================
CREATE TABLE comments (
    id BIGSERIAL PRIMARY KEY,
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    parent_id BIGINT,
    
    content TEXT NOT NULL,
    
    nickname_public BOOLEAN NOT NULL DEFAULT false,
    
    like_count INT NOT NULL DEFAULT 0,
    
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP,
    
    FOREIGN KEY (post_id) REFERENCES posts(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (parent_id) REFERENCES comments(id)
);

CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_id);
CREATE INDEX idx_comments_deleted_at ON comments(deleted_at) 
    WHERE deleted_at IS NULL;

-- ============================================
-- 4. open_mats (오픈매트)
-- ============================================
CREATE TABLE open_mats (
    id BIGSERIAL PRIMARY KEY,
    host_user_id BIGINT NOT NULL,
    
    -- 기본 정보
    title VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- 장소
    gym_name VARCHAR(200) NOT NULL,
    gym_place_id VARCHAR(100) NOT NULL,
    gym_address VARCHAR(300),
    
    -- 일정
    event_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    
    -- 정원
    max_participants INT NOT NULL,
    current_participants INT NOT NULL DEFAULT 0,
    
    -- 상태
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP,
    
    FOREIGN KEY (host_user_id) REFERENCES users(id),
    
    CONSTRAINT chk_participants 
        CHECK (current_participants >= 0 AND current_participants <= max_participants),
    CONSTRAINT chk_status 
        CHECK (status IN ('OPEN', 'CLOSED', 'CANCELLED', 'COMPLETED')),
    CONSTRAINT chk_time
        CHECK (end_time > start_time)
);

CREATE INDEX idx_open_mats_host_user_id ON open_mats(host_user_id);
CREATE INDEX idx_open_mats_event_date ON open_mats(event_date);
CREATE INDEX idx_open_mats_status ON open_mats(status);
CREATE INDEX idx_open_mats_gym_place_id ON open_mats(gym_place_id);
CREATE INDEX idx_open_mats_deleted_at ON open_mats(deleted_at) 
    WHERE deleted_at IS NULL;

-- ============================================
-- 5. open_mat_applications (오픈매트 신청)
-- ============================================
CREATE TABLE open_mat_applications (
    id BIGSERIAL PRIMARY KEY,
    open_mat_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    
    status VARCHAR(20) NOT NULL DEFAULT 'APPLIED',
    
    applied_at TIMESTAMP NOT NULL,
    cancelled_at TIMESTAMP,
    
    FOREIGN KEY (open_mat_id) REFERENCES open_mats(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    
    CONSTRAINT uk_application UNIQUE (open_mat_id, user_id),
    CONSTRAINT chk_application_status 
        CHECK (status IN ('APPLIED', 'CANCELLED'))
);

CREATE INDEX idx_applications_open_mat_id ON open_mat_applications(open_mat_id);
CREATE INDEX idx_applications_user_id ON open_mat_applications(user_id);
CREATE INDEX idx_applications_status ON open_mat_applications(status);

-- ============================================
-- 6. competitions (대회)
-- ============================================
CREATE TABLE competitions (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) UNIQUE NOT NULL,
    event_date DATE NOT NULL,
    location VARCHAR(100),
    federation VARCHAR(100),
    competition_level VARCHAR(20),
    
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP,
    
    CONSTRAINT chk_competition_level
        CHECK (competition_level IN ('INTERNATIONAL', 'NATIONAL', 'REGIONAL'))
);

CREATE INDEX idx_competitions_event_date ON competitions(event_date DESC);
CREATE INDEX idx_competitions_federation ON competitions(federation) 
    WHERE federation IS NOT NULL;
CREATE INDEX idx_competitions_deleted_at ON competitions(deleted_at) 
    WHERE deleted_at IS NULL;

-- ============================================
-- 7. competition_records (대회 기록)
-- ============================================
CREATE TABLE competition_records (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    competition_id BIGINT NOT NULL,
    
    -- 선수 정보 (스냅샷)
    user_real_name VARCHAR(100) NOT NULL,
    
    -- 수상 정보
    medal VARCHAR(20) NOT NULL,
    weight_class VARCHAR(50) NOT NULL,
    age_division VARCHAR(20) NOT NULL,
    
    -- 소속 정보 (대회 당시)
    gym_name VARCHAR(200) NOT NULL,
    gym_place_id VARCHAR(100) NOT NULL,
    instructor_name VARCHAR(100) NOT NULL,
    belt_level VARCHAR(20) NOT NULL,
    
    -- 검증
    verification_status VARCHAR(20) NOT NULL DEFAULT 'UNVERIFIED',
    
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    deleted_at TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (competition_id) REFERENCES competitions(id),
    
    CONSTRAINT chk_medal 
        CHECK (medal IN ('GOLD', 'SILVER', 'BRONZE')),
    CONSTRAINT chk_age_division 
        CHECK (age_division IN ('JUVENILE', 'ADULT', 'MASTER')),
    CONSTRAINT chk_belt_level_record
        CHECK (belt_level IN ('WHITE', 'BLUE', 'PURPLE', 'BROWN', 'BLACK')),
    CONSTRAINT chk_verification_status
        CHECK (verification_status IN ('UNVERIFIED', 'VERIFIED', 'REJECTED'))
);

CREATE INDEX idx_records_user_id ON competition_records(user_id);
CREATE INDEX idx_records_competition_id ON competition_records(competition_id);
CREATE INDEX idx_records_user_real_name ON competition_records(user_real_name);
CREATE INDEX idx_records_belt_level ON competition_records(belt_level);
CREATE INDEX idx_records_gym_place_id ON competition_records(gym_place_id);
CREATE INDEX idx_records_deleted_at ON competition_records(deleted_at) 
    WHERE deleted_at IS NULL;

-- ============================================
-- 초기 데이터 (옵션)
-- ============================================

-- 관리자 계정 (비밀번호는 애플리케이션에서 해시 후 입력)
-- INSERT INTO users (email, password_hash, real_name, nickname, is_real_name_public, role, created_at, updated_at) 
-- VALUES ('admin@bjj-community.com', 'HASHED_PASSWORD', '관리자', '관리자', false, 'ADMIN', NOW(), NOW());

-- 주요 대회 예시
-- INSERT INTO competitions (name, event_date, location, federation, competition_level, created_at, updated_at) VALUES
-- ('2024 서울오픈', '2024-03-15', '서울', 'KBJJA', 'NATIONAL', NOW(), NOW()),
-- ('2024 부산오픈', '2024-04-20', '부산', 'KBJJA', 'NATIONAL', NOW(), NOW()),
-- ('2024 전국체전', '2024-05-10', '서울', 'KBJJA', 'NATIONAL', NOW(), NOW());
```

---

## 테이블 관계 요약
```
users (회원)
 ├─→ posts (게시글)
 │    └─→ comments (댓글)
 ├─→ comments (댓글 작성자)
 ├─→ open_mats (오픈매트 개최자)
 ├─→ open_mat_applications (오픈매트 신청자)
 └─→ competition_records (대회 기록 소유자)

competitions (대회)
 └─→ competition_records (대회 기록)

comments (댓글)
 └─→ comments (대댓글, self-reference)
```

---

## 서비스별 소유권

**Spring Boot:**
```
✅ users (회원 관리, 인증)
✅ posts (게시판)
✅ comments (댓글)
✅ competitions (대회 관리)
✅ competition_records (랭킹)
```

**Golang:**
```
✅ open_mats (오픈매트 생성, 조회)
✅ open_mat_applications (신청, 동시성 처리)

읽기만:
📖 users (is_real_name_public 체크용)