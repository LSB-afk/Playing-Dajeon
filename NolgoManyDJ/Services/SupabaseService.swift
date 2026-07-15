import Foundation

// MARK: - Supabase Configuration
// 추후 Supabase 연동 시 사용할 서비스 레이어
// MVP에서는 MockDataService를 사용하고, 이후 이 클래스를 활성화

struct SupabaseConfig {
    // TODO: 실제 Supabase 프로젝트 URL/Key로 교체
    static let url = "https://your-project.supabase.co"
    static let anonKey = "your-anon-key"
}

// MARK: - Supabase SQL Schema
// 아래 SQL을 Supabase Dashboard에서 실행하여 테이블 생성
/*

-- 1. stores
CREATE TABLE stores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL,
    district TEXT NOT NULL,
    short_description TEXT,
    story_title TEXT,
    founder_story TEXT,
    signature_point TEXT,
    address TEXT,
    phone TEXT,
    opening_hours TEXT,
    website_url TEXT,
    instagram_url TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    thumbnail_url TEXT,
    cover_image_url TEXT,
    visit_tip TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. store_menu_items
CREATE TABLE store_menu_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    price TEXT,
    is_signature BOOLEAN DEFAULT FALSE
);

-- 3. store_images
CREATE TABLE store_images (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    sort_order INT DEFAULT 0,
    caption TEXT
);

-- 4. courses
CREATE TABLE courses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    theme TEXT NOT NULL,
    duration_minutes INT NOT NULL,
    district TEXT NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. course_stops
CREATE TABLE course_stops (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    stop_order INT NOT NULL,
    stay_minutes INT DEFAULT 30,
    note TEXT
);

-- 6. user_saved_stores
CREATE TABLE user_saved_stores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, store_id)
);

-- 7. user_saved_courses
CREATE TABLE user_saved_courses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, course_id)
);

-- 8. user_visits
CREATE TABLE user_visits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    visited_at TIMESTAMPTZ DEFAULT NOW(),
    verification_type TEXT DEFAULT 'manual',
    note TEXT
);

-- RLS policies (Row Level Security)
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_saved_stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_saved_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_visits ENABLE ROW LEVEL SECURITY;

-- Public read for stores, courses
CREATE POLICY "Public read stores" ON stores FOR SELECT USING (true);
CREATE POLICY "Public read store_images" ON store_images FOR SELECT USING (true);
CREATE POLICY "Public read courses" ON courses FOR SELECT USING (true);
CREATE POLICY "Public read course_stops" ON course_stops FOR SELECT USING (true);
CREATE POLICY "Public read store_menu_items" ON store_menu_items FOR SELECT USING (true);

-- User-specific policies
CREATE POLICY "Users manage own saves" ON user_saved_stores
    FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage own course saves" ON user_saved_courses
    FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage own visits" ON user_visits
    FOR ALL USING (auth.uid() = user_id);

*/

// MARK: - Supabase DataService (추후 구현)
// class SupabaseDataService: DataServiceProtocol { ... }
