-- ============================================================
-- PackFit: Initial Database Schema
-- ============================================================

-- ============================================================
-- PROFILES
-- ============================================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Trigger: auto-create profile on sign-up, pre-fill from OAuth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NULLIF(TRIM(CONCAT_WS(' ',
        NEW.raw_user_meta_data->>'given_name',
        NEW.raw_user_meta_data->>'family_name'
      )), ''),
      NEW.raw_user_meta_data->>'name',
      NULL
    ),
    COALESCE(
      NEW.raw_user_meta_data->>'avatar_url',
      NEW.raw_user_meta_data->>'picture',
      NULL
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- PACKS (Groups)
-- ============================================================
CREATE TABLE public.packs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  invite_code TEXT UNIQUE NOT NULL,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- PACK MEMBERS
-- ============================================================
CREATE TABLE public.pack_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pack_id UUID REFERENCES public.packs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(pack_id, user_id)
);

-- ============================================================
-- GOALS
-- ============================================================
CREATE TABLE public.goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pack_id UUID REFERENCES public.packs(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  target_minutes INT,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- CHECK-INS
-- ============================================================
CREATE TABLE public.check_ins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id UUID REFERENCES public.goals(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  checked_date DATE NOT NULL DEFAULT CURRENT_DATE,
  checked_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(goal_id, user_id, checked_date)
);

-- ============================================================
-- TIMER SESSIONS
-- ============================================================
CREATE TABLE public.timer_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code TEXT UNIQUE NOT NULL,
  pack_id UUID REFERENCES public.packs(id),
  created_by UUID REFERENCES public.profiles(id),
  state TEXT NOT NULL DEFAULT 'paused',
  elapsed_ms BIGINT NOT NULL DEFAULT 0,
  last_started_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- SESSION PARTICIPANTS
-- ============================================================
CREATE TABLE public.session_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES public.timer_sessions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(session_id, user_id)
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pack_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.check_ins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timer_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_participants ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Profiles are viewable by authenticated users"
  ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Packs
CREATE POLICY "Anyone can look up packs by invite code"
  ON public.packs FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can create packs"
  ON public.packs FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Admin can update pack"
  ON public.packs FOR UPDATE TO authenticated
  USING (id IN (SELECT pack_id FROM public.pack_members WHERE user_id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admin can delete pack"
  ON public.packs FOR DELETE TO authenticated
  USING (id IN (SELECT pack_id FROM public.pack_members WHERE user_id = auth.uid() AND role = 'admin'));

-- Pack members
CREATE POLICY "Pack members viewable by pack members"
  ON public.pack_members FOR SELECT TO authenticated
  USING (pack_id IN (SELECT pack_id FROM public.pack_members WHERE user_id = auth.uid()));
CREATE POLICY "Users can join packs"
  ON public.pack_members FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admin or self can remove members"
  ON public.pack_members FOR DELETE TO authenticated
  USING (
    auth.uid() = user_id
    OR pack_id IN (SELECT pack_id FROM public.pack_members WHERE user_id = auth.uid() AND role = 'admin')
  );

-- Goals
CREATE POLICY "Goals viewable by pack members"
  ON public.goals FOR SELECT TO authenticated
  USING (pack_id IN (SELECT pack_id FROM public.pack_members WHERE user_id = auth.uid()));
CREATE POLICY "Admin can create goals"
  ON public.goals FOR INSERT TO authenticated
  WITH CHECK (pack_id IN (SELECT pack_id FROM public.pack_members WHERE user_id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admin can update goals"
  ON public.goals FOR UPDATE TO authenticated
  USING (pack_id IN (SELECT pack_id FROM public.pack_members WHERE user_id = auth.uid() AND role = 'admin'));

-- Check-ins
CREATE POLICY "Check-ins viewable by pack members"
  ON public.check_ins FOR SELECT TO authenticated
  USING (goal_id IN (
    SELECT g.id FROM public.goals g
    JOIN public.pack_members pm ON pm.pack_id = g.pack_id
    WHERE pm.user_id = auth.uid()
  ));
CREATE POLICY "Users can check in for themselves"
  ON public.check_ins FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Timer sessions
CREATE POLICY "Timer sessions viewable"
  ON public.timer_sessions FOR SELECT TO authenticated
  USING (
    id IN (SELECT session_id FROM public.session_participants WHERE user_id = auth.uid())
    OR created_by = auth.uid()
    OR pack_id IN (SELECT pack_id FROM public.pack_members WHERE user_id = auth.uid())
  );
CREATE POLICY "Participants can update session"
  ON public.timer_sessions FOR UPDATE TO authenticated
  USING (id IN (SELECT session_id FROM public.session_participants WHERE user_id = auth.uid()));
CREATE POLICY "Authenticated users can create sessions"
  ON public.timer_sessions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = created_by);

-- Session participants
CREATE POLICY "Session participants viewable"
  ON public.session_participants FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can join sessions"
  ON public.session_participants FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can leave sessions"
  ON public.session_participants FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================
-- DATABASE FUNCTIONS
-- ============================================================

-- Generate 6-char invite/room code (no I/O/1/0 to avoid confusion)
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  code TEXT := '';
  i INT;
BEGIN
  FOR i IN 1..6 LOOP
    code := code || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN code;
END;
$$ LANGUAGE plpgsql;

-- Check if a pack's goal is complete for today
CREATE OR REPLACE FUNCTION public.is_goal_complete_today(p_goal_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  member_count INT;
  checkin_count INT;
BEGIN
  SELECT COUNT(*) INTO member_count
    FROM public.pack_members
    WHERE pack_id = (SELECT pack_id FROM public.goals WHERE id = p_goal_id);
  SELECT COUNT(*) INTO checkin_count
    FROM public.check_ins
    WHERE goal_id = p_goal_id AND checked_date = CURRENT_DATE;
  RETURN checkin_count >= member_count AND member_count > 0;
END;
$$ LANGUAGE plpgsql;

-- Calculate current streak for a pack's active goal
CREATE OR REPLACE FUNCTION public.get_pack_streak(p_pack_id UUID)
RETURNS INT AS $$
DECLARE
  streak INT := 0;
  check_date DATE := CURRENT_DATE;
  member_count INT;
  day_checkins INT;
  active_goal_id UUID;
BEGIN
  SELECT id INTO active_goal_id FROM public.goals
    WHERE pack_id = p_pack_id AND is_active = true LIMIT 1;
  IF active_goal_id IS NULL THEN RETURN 0; END IF;

  SELECT COUNT(*) INTO member_count FROM public.pack_members WHERE pack_id = p_pack_id;
  IF member_count = 0 THEN RETURN 0; END IF;

  -- Walk backwards from yesterday (today might still be in progress)
  check_date := CURRENT_DATE - 1;
  LOOP
    SELECT COUNT(*) INTO day_checkins FROM public.check_ins
      WHERE goal_id = active_goal_id AND checked_date = check_date;
    EXIT WHEN day_checkins < member_count;
    streak := streak + 1;
    check_date := check_date - 1;
  END LOOP;

  -- If today is also complete, add it
  SELECT COUNT(*) INTO day_checkins FROM public.check_ins
    WHERE goal_id = active_goal_id AND checked_date = CURRENT_DATE;
  IF day_checkins >= member_count THEN
    streak := streak + 1;
  END IF;

  RETURN streak;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- REALTIME
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.timer_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.check_ins;
