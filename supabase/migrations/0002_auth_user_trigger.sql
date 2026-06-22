-- Recreate the trigger on auth.users that provisions a public.profiles row on signup.
-- This lives on the auth schema, so it is NOT captured by a `public`-schema dump and
-- must be applied explicitly. The handle_new_user() function is defined in 0001.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
