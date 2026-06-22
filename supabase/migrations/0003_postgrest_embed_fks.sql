-- Add foreign keys from athlete_profiles/assignments to public.profiles so
-- PostgREST can resolve the embedded selects the coach views rely on, e.g.
--   profiles.select('*, athlete_profiles(*), assignments(...)').eq('role','athlete')
--
-- The original schema only linked these tables to auth.users(id). PostgREST will
-- not chain an embed through the auth schema, so the coach "Athletes" list and
-- dashboard queries failed with PGRST200 ("Could not find a relationship ...")
-- and returned null, rendering "No athletes yet" even when athletes existed.
--
-- These FKs sit ALONGSIDE the existing auth.users FKs (a column may carry more
-- than one FK). Data is 1:1 (profiles.id = auth.users.id), so no orphans.

ALTER TABLE public.athlete_profiles
  ADD CONSTRAINT athlete_profiles_id_profiles_fkey
  FOREIGN KEY (id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.assignments
  ADD CONSTRAINT assignments_athlete_id_profiles_fkey
  FOREIGN KEY (athlete_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- Tell PostgREST to refresh its schema cache so the new relationships are picked up.
NOTIFY pgrst, 'reload schema';
