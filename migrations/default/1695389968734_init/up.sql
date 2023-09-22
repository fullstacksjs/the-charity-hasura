SET check_function_bodies = false;
CREATE FUNCTION public.author_full_name(code text) RETURNS text
    LANGUAGE sql STABLE
    AS $$
  SELECT 'F' || LPAD(code, '5', '0')
$$;
CREATE FUNCTION public.check_status() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
  column_count INTEGER;
  null_count INTEGER;
BEGIN
  -- Get the total number of columns in the table
  SELECT COUNT(*) INTO column_count
  FROM information_schema.columns
  WHERE table_name = 'householder'; -- Replace 'your_table_name' with your actual table name
  -- Check if any column is NULL
  EXECUTE format('
    SELECT COUNT(*)
    FROM your_table_name
    WHERE %s IS NULL
  ', (SELECT STRING_AGG(column_name, ' OR ')
      FROM information_schema.columns
      WHERE table_name = 'householder'))
  INTO null_count;
  -- Return the appropriate status
  IF null_count = 0 THEN
    RETURN 'COMPLETED';
  ELSE
    RETURN 'DRAFTED';
  END IF;
END;
$$;
CREATE TABLE public.household (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    status text DEFAULT 'Draft'::text NOT NULL,
    severity text DEFAULT 'Normal'::text NOT NULL,
    db_code integer NOT NULL
);
CREATE FUNCTION public.count_members(household_row public.household) RETURNS integer
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
  member_count INT;
BEGIN
  SELECT COUNT(*) INTO member_count
  FROM member
  WHERE household_id = household_row.id;
  RETURN member_count;
END;
$$;
CREATE FUNCTION public.format_code(household_row public.household) RETURNS text
    LANGUAGE sql STABLE
    AS $$
  SELECT 'F' || LPAD(household_row.db_code::text, '5', '0')
$$;
CREATE FUNCTION public.function_create_householder() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO
        householder(family_id)
        VALUES(new.id);
           RETURN new;
END;
$$;
CREATE TABLE public.householder (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    surname text,
    father_name text,
    nationality text,
    national_id text,
    gender text,
    city text,
    religion text,
    dob date,
    household_id uuid NOT NULL,
    description text,
    income money,
    rent money,
    financial_comment text,
    addiction_status text,
    disability_status text,
    disability_description text,
    health_status text,
    health_description text,
    health_comment text,
    province text,
    neighborhood text,
    address text,
    zip_code text,
    prior_accommodation_address text,
    accommodation_type text
);
CREATE FUNCTION public.get_householder_status(householder_row public.householder) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    col TEXT;
    query_text TEXT;
    is_draft BOOLEAN = FALSE;
BEGIN
    FOR col IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'householder'
    LOOP
        query_text = format('SELECT ($1.%I IS NULL)', col);
        EXECUTE query_text INTO is_draft USING householder_row;
        IF is_draft = 't' THEN
            RETURN 'Draft';
        END IF;
    END LOOP;
    RETURN 'Completed';
END;
$_$;
CREATE TABLE public.member (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    household_id uuid NOT NULL,
    surname text,
    nationality text,
    father_name text,
    religion text,
    gender text,
    dob date,
    national_id text
);
CREATE FUNCTION public.get_member_status(member_row public.member) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    col TEXT;
    query_text TEXT;
    is_draft BOOLEAN = FALSE;
BEGIN
    FOR col IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'member'
    LOOP
        query_text = format('SELECT ($1.%I IS NULL)', col);
        EXECUTE query_text INTO is_draft USING member_row;
        IF is_draft = 't' THEN
            RETURN 'Draft';
        END IF;
    END LOOP;
    RETURN 'Completed';
END;
$_$;
CREATE FUNCTION public.set_current_timestamp_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _new record;
BEGIN
  _new := NEW;
  _new."updated_at" = NOW();
  RETURN _new;
END;
$$;
CREATE TABLE public.accommodation_type (
    value text NOT NULL
);
CREATE TABLE public.addiction_status (
    value text NOT NULL
);
CREATE TABLE public.bank_account (
    bank_name text NOT NULL,
    card_name text NOT NULL,
    account_number text NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    householder_id uuid NOT NULL
);
CREATE TABLE public.city (
    value text NOT NULL
);
CREATE TABLE public.disability_status (
    value text NOT NULL
);
CREATE TABLE public.document (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    url text NOT NULL,
    householder_id uuid NOT NULL
);
CREATE SEQUENCE public.family_code_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.family_code_seq OWNED BY public.household.db_code;
CREATE TABLE public.gender (
    value text NOT NULL
);
CREATE TABLE public.health_status (
    value text NOT NULL
);
CREATE TABLE public.household_project (
    project_id uuid NOT NULL,
    household_id uuid NOT NULL,
    count integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
COMMENT ON TABLE public.household_project IS 'Relation between projects and households';
CREATE TABLE public.household_severity (
    value text NOT NULL,
    description text
);
CREATE TABLE public.household_status (
    value text NOT NULL,
    description text
);
CREATE TABLE public.insurance (
    name text NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    householder_id uuid NOT NULL
);
CREATE TABLE public.job (
    title text NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    householder_id uuid NOT NULL
);
CREATE TABLE public.nationality (
    value text NOT NULL
);
CREATE TABLE public.project (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    description text,
    status text DEFAULT 'Planning'::text NOT NULL,
    due_date date,
    start_date date DEFAULT now()
);
CREATE TABLE public.project_status (
    value text NOT NULL,
    comment text
);
CREATE TABLE public.religion (
    value text NOT NULL
);
CREATE TABLE public.skill (
    name text NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    householder_id uuid NOT NULL
);
CREATE TABLE public.subsidy (
    name text NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    householder_id uuid NOT NULL
);
ALTER TABLE ONLY public.household ALTER COLUMN db_code SET DEFAULT nextval('public.family_code_seq'::regclass);
ALTER TABLE ONLY public.accommodation_type
    ADD CONSTRAINT accommodation_type_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.addiction_status
    ADD CONSTRAINT addiction_status_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.bank_account
    ADD CONSTRAINT bank_account_id_key UNIQUE (id);
ALTER TABLE ONLY public.bank_account
    ADD CONSTRAINT bank_account_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.city
    ADD CONSTRAINT city_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.disability_status
    ADD CONSTRAINT disability_status_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gender
    ADD CONSTRAINT gender_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.health_status
    ADD CONSTRAINT health_status_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.household
    ADD CONSTRAINT household_code_key UNIQUE (db_code);
ALTER TABLE ONLY public.household
    ADD CONSTRAINT household_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.household_project
    ADD CONSTRAINT household_project_pkey PRIMARY KEY (project_id, household_id);
ALTER TABLE ONLY public.household_severity
    ADD CONSTRAINT household_severity_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.household_status
    ADD CONSTRAINT household_status_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.householder
    ADD CONSTRAINT householder_household_id_key UNIQUE (household_id);
ALTER TABLE ONLY public.householder
    ADD CONSTRAINT householder_id_key UNIQUE (id);
ALTER TABLE ONLY public.householder
    ADD CONSTRAINT householder_pkey PRIMARY KEY (household_id);
ALTER TABLE ONLY public.insurance
    ADD CONSTRAINT insurance_id_key UNIQUE (id);
ALTER TABLE ONLY public.insurance
    ADD CONSTRAINT insurance_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.job
    ADD CONSTRAINT job_id_key UNIQUE (id);
ALTER TABLE ONLY public.job
    ADD CONSTRAINT job_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.nationality
    ADD CONSTRAINT nationality_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.project_status
    ADD CONSTRAINT project_status_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.religion
    ADD CONSTRAINT religion_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.skill
    ADD CONSTRAINT skill_id_key UNIQUE (id);
ALTER TABLE ONLY public.skill
    ADD CONSTRAINT skill_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.subsidy
    ADD CONSTRAINT subsidy_id_key UNIQUE (id);
ALTER TABLE ONLY public.subsidy
    ADD CONSTRAINT subsidy_pkey PRIMARY KEY (id);
CREATE TRIGGER set_public_household_project_updated_at BEFORE UPDATE ON public.household_project FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
COMMENT ON TRIGGER set_public_household_project_updated_at ON public.household_project IS 'trigger to set value of column "updated_at" to current timestamp on row update';
CREATE TRIGGER set_public_household_updated_at BEFORE UPDATE ON public.household FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
COMMENT ON TRIGGER set_public_household_updated_at ON public.household IS 'trigger to set value of column "updated_at" to current timestamp on row update';
CREATE TRIGGER set_public_householder_updated_at BEFORE UPDATE ON public.householder FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
COMMENT ON TRIGGER set_public_householder_updated_at ON public.householder IS 'trigger to set value of column "updated_at" to current timestamp on row update';
CREATE TRIGGER set_public_member_updated_at BEFORE UPDATE ON public.member FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
COMMENT ON TRIGGER set_public_member_updated_at ON public.member IS 'trigger to set value of column "updated_at" to current timestamp on row update';
CREATE TRIGGER set_public_project_updated_at BEFORE UPDATE ON public.project FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
COMMENT ON TRIGGER set_public_project_updated_at ON public.project IS 'trigger to set value of column "updated_at" to current timestamp on row update';
ALTER TABLE ONLY public.bank_account
    ADD CONSTRAINT bank_account_householder_id_fkey FOREIGN KEY (householder_id) REFERENCES public.householder(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_householder_id_fkey FOREIGN KEY (householder_id) REFERENCES public.householder(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.household
    ADD CONSTRAINT family_severity_fkey FOREIGN KEY (severity) REFERENCES public.household_severity(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.household
    ADD CONSTRAINT family_status_fkey FOREIGN KEY (status) REFERENCES public.household_status(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.household_project
    ADD CONSTRAINT household_project_fkey FOREIGN KEY (household_id) REFERENCES public.household(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.householder
    ADD CONSTRAINT householder_accommodation_type_fkey FOREIGN KEY (accommodation_type) REFERENCES public.accommodation_type(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.householder
    ADD CONSTRAINT householder_addiction_status_fkey FOREIGN KEY (addiction_status) REFERENCES public.addiction_status(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.householder
    ADD CONSTRAINT householder_city_fkey FOREIGN KEY (city) REFERENCES public.city(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.householder
    ADD CONSTRAINT householder_disability_status_fkey FOREIGN KEY (disability_status) REFERENCES public.disability_status(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.householder
    ADD CONSTRAINT householder_gender_fkey FOREIGN KEY (gender) REFERENCES public.gender(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.householder
    ADD CONSTRAINT householder_health_status_fkey FOREIGN KEY (health_status) REFERENCES public.health_status(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.householder
    ADD CONSTRAINT householder_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.household(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.householder
    ADD CONSTRAINT householder_nationality_fkey FOREIGN KEY (nationality) REFERENCES public.nationality(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.householder
    ADD CONSTRAINT householder_religion_fkey FOREIGN KEY (religion) REFERENCES public.religion(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.insurance
    ADD CONSTRAINT insurance_householder_id_fkey FOREIGN KEY (householder_id) REFERENCES public.householder(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.job
    ADD CONSTRAINT job_householder_id_fkey FOREIGN KEY (householder_id) REFERENCES public.householder(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_family_id_fkey FOREIGN KEY (household_id) REFERENCES public.household(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_gender_fkey FOREIGN KEY (gender) REFERENCES public.gender(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_nationality_fkey FOREIGN KEY (nationality) REFERENCES public.nationality(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_religion_fkey FOREIGN KEY (religion) REFERENCES public.religion(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.household_project
    ADD CONSTRAINT project_household_fkey FOREIGN KEY (project_id) REFERENCES public.project(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_status_fkey FOREIGN KEY (status) REFERENCES public.project_status(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.skill
    ADD CONSTRAINT skill_householder_id_fkey FOREIGN KEY (householder_id) REFERENCES public.householder(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.subsidy
    ADD CONSTRAINT subsidy_householder_id_fkey FOREIGN KEY (householder_id) REFERENCES public.householder(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
