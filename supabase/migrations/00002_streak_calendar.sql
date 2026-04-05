-- Add best_streak column to packs table
ALTER TABLE public.packs ADD COLUMN IF NOT EXISTS best_streak INT DEFAULT 0;

-- Enhanced streak function that also tracks and returns the best streak
CREATE OR REPLACE FUNCTION public.get_pack_streak_with_best(p_pack_id UUID)
RETURNS TABLE(current_streak INT, best_streak INT) AS $$
DECLARE
  v_streak INT := 0;
  v_check_date DATE;
  v_member_count INT;
  v_day_checkins INT;
  v_active_goal_id UUID;
  v_best INT;
BEGIN
  SELECT id INTO v_active_goal_id FROM public.goals
    WHERE pack_id = p_pack_id AND is_active = true LIMIT 1;

  IF v_active_goal_id IS NULL THEN
    RETURN QUERY SELECT 0, COALESCE((SELECT p.best_streak FROM public.packs p WHERE p.id = p_pack_id), 0);
    RETURN;
  END IF;

  SELECT COUNT(*)::INT INTO v_member_count FROM public.pack_members WHERE pack_id = p_pack_id;
  IF v_member_count = 0 THEN
    RETURN QUERY SELECT 0, 0;
    RETURN;
  END IF;

  -- Walk backwards from yesterday
  v_check_date := CURRENT_DATE - 1;
  LOOP
    SELECT COUNT(*)::INT INTO v_day_checkins FROM public.check_ins
      WHERE goal_id = v_active_goal_id AND checked_date = v_check_date;
    EXIT WHEN v_day_checkins < v_member_count;
    v_streak := v_streak + 1;
    v_check_date := v_check_date - 1;
  END LOOP;

  -- Check if today is also complete
  SELECT COUNT(*)::INT INTO v_day_checkins FROM public.check_ins
    WHERE goal_id = v_active_goal_id AND checked_date = CURRENT_DATE;
  IF v_day_checkins >= v_member_count THEN
    v_streak := v_streak + 1;
  END IF;

  -- Update best_streak if current exceeds it
  SELECT COALESCE(p.best_streak, 0) INTO v_best FROM public.packs p WHERE p.id = p_pack_id;
  IF v_streak > v_best THEN
    UPDATE public.packs SET best_streak = v_streak WHERE id = p_pack_id;
    v_best := v_streak;
  END IF;

  RETURN QUERY SELECT v_streak, v_best;
END;
$$ LANGUAGE plpgsql;
