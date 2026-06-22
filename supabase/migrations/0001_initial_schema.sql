--
-- PostgreSQL database dump
--

\restrict HrZAG5tcvXQBzCBEgGgxokADDc3WMhPtwMc6EK1xsJcpiN0mQ9yd30ZQGIHKRUW

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
  insert into public.profiles (id, name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'athlete')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;


--
-- Name: is_coach(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_coach() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
  select exists(
    select 1 from public.profiles
    where id = auth.uid() and role = 'coach'
  );
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    athlete_id uuid NOT NULL,
    template_id uuid NOT NULL,
    start_date date NOT NULL,
    coach_notes text DEFAULT ''::text,
    modifications jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: athlete_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.athlete_profiles (
    id uuid NOT NULL,
    race_date date,
    race_format text,
    level text,
    weekly_run text,
    strength_exp text,
    injuries text,
    available_days text[] DEFAULT '{}'::text[],
    equipment text,
    hyrox_exp text,
    partner_id uuid,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: checkins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checkins (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    athlete_id uuid NOT NULL,
    date date NOT NULL,
    energy integer,
    soreness integer,
    sleep integer,
    mood integer,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT checkins_energy_check CHECK (((energy >= 1) AND (energy <= 5))),
    CONSTRAINT checkins_mood_check CHECK (((mood >= 1) AND (mood <= 5))),
    CONSTRAINT checkins_sleep_check CHECK (((sleep >= 1) AND (sleep <= 5))),
    CONSTRAINT checkins_soreness_check CHECK (((soreness >= 1) AND (soreness <= 5)))
);


--
-- Name: coach_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coach_notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    athlete_id uuid NOT NULL,
    coach_id uuid NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: library; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.library (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    type text,
    detail text,
    notes text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: plan_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plan_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    length_weeks integer NOT NULL,
    level text,
    format text,
    phases jsonb DEFAULT '[]'::jsonb NOT NULL,
    workouts jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    name text NOT NULL,
    role text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['coach'::text, 'athlete'::text])))
);


--
-- Name: workout_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workout_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    athlete_id uuid NOT NULL,
    week integer NOT NULL,
    day integer NOT NULL,
    completed boolean DEFAULT false NOT NULL,
    rpe text,
    feedback text,
    next_day_soreness text,
    adjustment_requested boolean DEFAULT false,
    adjustment_note text,
    adjustment_resolved boolean DEFAULT false,
    adjustment_reply text,
    coach_reviewed boolean DEFAULT false,
    coach_reply text,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: assignments assignments_athlete_id_template_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_athlete_id_template_id_key UNIQUE (athlete_id, template_id);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: athlete_profiles athlete_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.athlete_profiles
    ADD CONSTRAINT athlete_profiles_pkey PRIMARY KEY (id);


--
-- Name: checkins checkins_athlete_id_date_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkins
    ADD CONSTRAINT checkins_athlete_id_date_key UNIQUE (athlete_id, date);


--
-- Name: checkins checkins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkins
    ADD CONSTRAINT checkins_pkey PRIMARY KEY (id);


--
-- Name: coach_notes coach_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coach_notes
    ADD CONSTRAINT coach_notes_pkey PRIMARY KEY (id);


--
-- Name: library library_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.library
    ADD CONSTRAINT library_pkey PRIMARY KEY (id);


--
-- Name: plan_templates plan_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_templates
    ADD CONSTRAINT plan_templates_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: workout_logs workout_logs_athlete_id_week_day_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workout_logs
    ADD CONSTRAINT workout_logs_athlete_id_week_day_key UNIQUE (athlete_id, week, day);


--
-- Name: workout_logs workout_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workout_logs
    ADD CONSTRAINT workout_logs_pkey PRIMARY KEY (id);


--
-- Name: idx_assignments_athlete; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assignments_athlete ON public.assignments USING btree (athlete_id);


--
-- Name: idx_checkins_athlete; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_checkins_athlete ON public.checkins USING btree (athlete_id);


--
-- Name: idx_coach_notes_athlete; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_coach_notes_athlete ON public.coach_notes USING btree (athlete_id);


--
-- Name: idx_library_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_library_created_by ON public.library USING btree (created_by);


--
-- Name: idx_workout_logs_athlete; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workout_logs_athlete ON public.workout_logs USING btree (athlete_id);


--
-- Name: assignments assignments_athlete_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_athlete_id_fkey FOREIGN KEY (athlete_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: assignments assignments_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.plan_templates(id);


--
-- Name: athlete_profiles athlete_profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.athlete_profiles
    ADD CONSTRAINT athlete_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: athlete_profiles athlete_profiles_partner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.athlete_profiles
    ADD CONSTRAINT athlete_profiles_partner_id_fkey FOREIGN KEY (partner_id) REFERENCES auth.users(id);


--
-- Name: checkins checkins_athlete_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkins
    ADD CONSTRAINT checkins_athlete_id_fkey FOREIGN KEY (athlete_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: coach_notes coach_notes_athlete_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coach_notes
    ADD CONSTRAINT coach_notes_athlete_id_fkey FOREIGN KEY (athlete_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: coach_notes coach_notes_coach_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coach_notes
    ADD CONSTRAINT coach_notes_coach_id_fkey FOREIGN KEY (coach_id) REFERENCES auth.users(id);


--
-- Name: library library_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.library
    ADD CONSTRAINT library_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: plan_templates plan_templates_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_templates
    ADD CONSTRAINT plan_templates_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: workout_logs workout_logs_athlete_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workout_logs
    ADD CONSTRAINT workout_logs_athlete_id_fkey FOREIGN KEY (athlete_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: assignments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;

--
-- Name: checkins athlete manages own checkins; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "athlete manages own checkins" ON public.checkins USING ((athlete_id = auth.uid()));


--
-- Name: workout_logs athlete manages own logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "athlete manages own logs" ON public.workout_logs USING ((athlete_id = auth.uid()));


--
-- Name: athlete_profiles athlete manages own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "athlete manages own profile" ON public.athlete_profiles USING ((auth.uid() = id));


--
-- Name: plan_templates athlete reads assigned template; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "athlete reads assigned template" ON public.plan_templates FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.assignments
  WHERE ((assignments.athlete_id = auth.uid()) AND (assignments.template_id = plan_templates.id)))));


--
-- Name: library athlete reads library; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "athlete reads library" ON public.library FOR SELECT USING (true);


--
-- Name: assignments athlete reads own assignment; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "athlete reads own assignment" ON public.assignments FOR SELECT USING ((athlete_id = auth.uid()));


--
-- Name: coach_notes athlete reads own notes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "athlete reads own notes" ON public.coach_notes FOR SELECT USING ((athlete_id = auth.uid()));


--
-- Name: athlete_profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.athlete_profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: checkins; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.checkins ENABLE ROW LEVEL SECURITY;

--
-- Name: athlete_profiles coach inserts athlete profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "coach inserts athlete profiles" ON public.athlete_profiles FOR INSERT WITH CHECK (public.is_coach());


--
-- Name: assignments coach manages assignments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "coach manages assignments" ON public.assignments USING (public.is_coach());


--
-- Name: library coach manages library; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "coach manages library" ON public.library USING (public.is_coach());


--
-- Name: coach_notes coach manages notes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "coach manages notes" ON public.coach_notes USING (public.is_coach());


--
-- Name: plan_templates coach manages templates; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "coach manages templates" ON public.plan_templates USING (public.is_coach());


--
-- Name: athlete_profiles coach reads all athlete profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "coach reads all athlete profiles" ON public.athlete_profiles FOR SELECT USING (public.is_coach());


--
-- Name: checkins coach reads all checkins; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "coach reads all checkins" ON public.checkins FOR SELECT USING (public.is_coach());


--
-- Name: workout_logs coach reads all logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "coach reads all logs" ON public.workout_logs FOR SELECT USING (public.is_coach());


--
-- Name: athlete_profiles coach updates athlete profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "coach updates athlete profiles" ON public.athlete_profiles FOR UPDATE USING (public.is_coach());


--
-- Name: workout_logs coach updates logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "coach updates logs" ON public.workout_logs FOR UPDATE USING (public.is_coach());


--
-- Name: coach_notes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.coach_notes ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles insert own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "insert own profile" ON public.profiles FOR INSERT WITH CHECK ((auth.uid() = id));


--
-- Name: library; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.library ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "own profile" ON public.profiles FOR SELECT USING (((auth.uid() = id) OR public.is_coach()));


--
-- Name: plan_templates; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.plan_templates ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles update own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "update own profile" ON public.profiles FOR UPDATE USING ((auth.uid() = id));


--
-- Name: workout_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict HrZAG5tcvXQBzCBEgGgxokADDc3WMhPtwMc6EK1xsJcpiN0mQ9yd30ZQGIHKRUW

