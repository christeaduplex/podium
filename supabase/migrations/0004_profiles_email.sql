-- The coach UI displays athlete email in several places (athletes list, athlete
-- detail header, partner card) and explicitly selects it for the partner lookup
-- (index.html: profiles.select('id,name,email')). Email lives in auth.users, which
-- the anon client cannot read, so it was surfaced as undefined and the explicit
-- partner select failed outright (column did not exist).
--
-- Add a profiles.email column, backfill from auth.users, and keep it populated via
-- the signup trigger. Email is only readable by the row owner or a coach (existing
-- "own profile" SELECT policy: auth.uid() = id OR is_coach()), matching intent.

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email text;

UPDATE public.profiles p
   SET email = u.email
  FROM auth.users u
 WHERE u.id = p.id AND p.email IS DISTINCT FROM u.email;

-- Recreate the signup trigger function so new users get their email recorded.
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER AS $$
begin
  insert into public.profiles (id, name, role, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'athlete'),
    new.email
  )
  on conflict (id) do update set email = excluded.email
    where public.profiles.email is null;
  return new;
end;
$$;

NOTIFY pgrst, 'reload schema';
