
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


-- Name: applicant__documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applicant__documents (
    id bigint NOT NULL,
    type character varying(255) NOT NULL,
    application_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    url_id bigint NOT NULL
);


--
-- Name: applicant__documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applicant__documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicant__documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applicant__documents_id_seq OWNED BY public.applicant__documents.id;


--
-- Name: applicant__emergency_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applicant__emergency_contacts (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    relationship character varying(255) NOT NULL,
    phone character varying(255) NOT NULL,
    address character varying(255),
    application_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    email public.citext
);


--
-- Name: applicant__emergency_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applicant__emergency_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicant__emergency_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applicant__emergency_contacts_id_seq OWNED BY public.applicant__emergency_contacts.id;


--
-- Name: applicant__employments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applicant__employments (
    id bigint NOT NULL,
    employer character varying(255) NOT NULL,
    address character varying(255) NOT NULL,
    duration character varying(255) NOT NULL,
    supervisor character varying(255) NOT NULL,
    salary numeric NOT NULL,
    phone character varying(255) NOT NULL,
    application_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    person_id bigint,
    current boolean DEFAULT true NOT NULL,
    email public.citext
);


--
-- Name: applicant__employments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applicant__employments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicant__employments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applicant__employments_id_seq OWNED BY public.applicant__employments.id;


--
-- Name: applicant__histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applicant__histories (
    id bigint NOT NULL,
    address character varying(255) NOT NULL,
    landlord_name character varying(255),
    landlord_phone character varying(255),
    rent boolean DEFAULT false NOT NULL,
    rental_amount numeric,
    residency_length character varying(255) NOT NULL,
    application_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    landlord_email character varying(255),
    current boolean DEFAULT false NOT NULL,
    street character varying(255),
    unit character varying(255),
    city character varying(255),
    state character varying(255),
    zip character varying(255)
);


--
-- Name: applicant__histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applicant__histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicant__histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applicant__histories_id_seq OWNED BY public.applicant__histories.id;


--
-- Name: applicant__incomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applicant__incomes (
    id bigint NOT NULL,
    description character varying(255) NOT NULL,
    salary numeric NOT NULL,
    application_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: applicant__incomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applicant__incomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicant__incomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applicant__incomes_id_seq OWNED BY public.applicant__incomes.id;


--
-- Name: applicant__memos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applicant__memos (
    id bigint NOT NULL,
    note character varying(255) NOT NULL,
    application_id bigint NOT NULL,
    admin_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: applicant__memos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applicant__memos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicant__memos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applicant__memos_id_seq OWNED BY public.applicant__memos.id;


--
-- Name: applicant__move_ins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applicant__move_ins (
    id bigint NOT NULL,
    expected_move_in date NOT NULL,
    application_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    unit_number character varying(255),
    unit_id bigint,
    floor_plan_id bigint
);


--
-- Name: applicant__move_ins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applicant__move_ins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicant__move_ins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applicant__move_ins_id_seq OWNED BY public.applicant__move_ins.id;


--
-- Name: applicant__occupants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applicant__occupants (
    id bigint NOT NULL,
    full_name character varying(255) NOT NULL,
    ssn text NOT NULL,
    email public.citext NOT NULL,
    home_phone character varying(255),
    work_phone character varying(255),
    cell_phone character varying(255),
    dob date NOT NULL,
    dl_number character varying(255) NOT NULL,
    dl_state character varying(255) NOT NULL,
    application_id bigint NOT NULL,
    status character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    order_id character varying(255),
    CONSTRAINT must_have_a_phone CHECK (((home_phone IS NOT NULL) OR (work_phone IS NOT NULL) OR (cell_phone IS NOT NULL)))
);


--
-- Name: applicant__occupants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applicant__occupants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicant__occupants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applicant__occupants_id_seq OWNED BY public.applicant__occupants.id;


--
-- Name: applicant__pets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applicant__pets (
    id bigint NOT NULL,
    type character varying(255) NOT NULL,
    breed character varying(255) NOT NULL,
    weight character varying(255) NOT NULL,
    application_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    name character varying(255) NOT NULL
);


--
-- Name: applicant__pets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applicant__pets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicant__pets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applicant__pets_id_seq OWNED BY public.applicant__pets.id;


--
-- Name: applicant__rent_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applicant__rent_applications (
    id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    property_id bigint NOT NULL,
    status character varying(255) DEFAULT 'submitted'::character varying NOT NULL,
    approval_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    device_id bigint,
    prospect_id bigint,
    bluemoon_lease_id character varying(255),
    declined_on date,
    declined_reason character varying(255),
    declined_by character varying(255),
    is_conditional boolean DEFAULT false NOT NULL,
    lang character varying(255),
    start_time integer,
    security_deposit_id bigint,
    referral character varying(255)
);


--
-- Name: applicant__rent_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applicant__rent_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicant__rent_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applicant__rent_applications_id_seq OWNED BY public.applicant__rent_applications.id;


--
-- Name: applicant__saved_forms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applicant__saved_forms (
    id bigint NOT NULL,
    email public.citext NOT NULL,
    crypted_form text NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    form_summary jsonb DEFAULT '{}'::jsonb,
    name character varying(255),
    lang character varying(255),
    start_time timestamp(0) without time zone
);


--
-- Name: applicant__saved_forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applicant__saved_forms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicant__saved_forms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applicant__saved_forms_id_seq OWNED BY public.applicant__saved_forms.id;


--
-- Name: applicant__vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applicant__vehicles (
    id bigint NOT NULL,
    make_model character varying(255) NOT NULL,
    color character varying(255) NOT NULL,
    license_plate character varying(255) NOT NULL,
    state character varying(255) NOT NULL,
    application_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: applicant__vehicles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applicant__vehicles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicant__vehicles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applicant__vehicles_id_seq OWNED BY public.applicant__vehicles.id;



--
-- Name: applicant__documents applicant__documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__documents
    ADD CONSTRAINT applicant__documents_pkey PRIMARY KEY (id);


--
-- Name: applicant__emergency_contacts applicant__emergency_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__emergency_contacts
    ADD CONSTRAINT applicant__emergency_contacts_pkey PRIMARY KEY (id);


--
-- Name: applicant__employments applicant__employments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__employments
    ADD CONSTRAINT applicant__employments_pkey PRIMARY KEY (id);


--
-- Name: applicant__histories applicant__histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__histories
    ADD CONSTRAINT applicant__histories_pkey PRIMARY KEY (id);


--
-- Name: applicant__incomes applicant__incomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__incomes
    ADD CONSTRAINT applicant__incomes_pkey PRIMARY KEY (id);


--
-- Name: applicant__memos applicant__memos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__memos
    ADD CONSTRAINT applicant__memos_pkey PRIMARY KEY (id);


--
-- Name: applicant__move_ins applicant__move_ins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__move_ins
    ADD CONSTRAINT applicant__move_ins_pkey PRIMARY KEY (id);


--
-- Name: applicant__occupants applicant__occupants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__occupants
    ADD CONSTRAINT applicant__occupants_pkey PRIMARY KEY (id);


--
-- Name: applicant__pets applicant__pets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__pets
    ADD CONSTRAINT applicant__pets_pkey PRIMARY KEY (id);


--
-- Name: applicant__rent_applications applicant__rent_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__rent_applications
    ADD CONSTRAINT applicant__rent_applications_pkey PRIMARY KEY (id);


--
-- Name: applicant__saved_forms applicant__saved_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__saved_forms
    ADD CONSTRAINT applicant__saved_forms_pkey PRIMARY KEY (id);


--
-- Name: applicant__vehicles applicant__vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__vehicles
    ADD CONSTRAINT applicant__vehicles_pkey PRIMARY KEY (id);




--
-- Name: applicant__documents_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__documents_application_id_index ON public.applicant__documents USING btree (application_id);


--
-- Name: applicant__documents_url_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__documents_url_id_index ON public.applicant__documents USING btree (url_id);


--
-- Name: applicant__emergency_contacts_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__emergency_contacts_application_id_index ON public.applicant__emergency_contacts USING btree (application_id);


--
-- Name: applicant__employments_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__employments_application_id_index ON public.applicant__employments USING btree (application_id);


--
-- Name: applicant__employments_person_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__employments_person_id_index ON public.applicant__employments USING btree (person_id);


--
-- Name: applicant__histories_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__histories_application_id_index ON public.applicant__histories USING btree (application_id);


--
-- Name: applicant__incomes_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__incomes_application_id_index ON public.applicant__incomes USING btree (application_id);


--
-- Name: applicant__memos_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__memos_application_id_index ON public.applicant__memos USING btree (application_id);


--
-- Name: applicant__move_ins_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__move_ins_application_id_index ON public.applicant__move_ins USING btree (application_id);


--
-- Name: applicant__move_ins_floor_plan_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__move_ins_floor_plan_id_index ON public.applicant__move_ins USING btree (floor_plan_id);


--
-- Name: applicant__occupants_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__occupants_application_id_index ON public.applicant__occupants USING btree (application_id);


--
-- Name: applicant__pets_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__pets_application_id_index ON public.applicant__pets USING btree (application_id);


--
-- Name: applicant__rent_applications_device_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__rent_applications_device_id_index ON public.applicant__rent_applications USING btree (device_id);


--
-- Name: applicant__rent_applications_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__rent_applications_property_id_index ON public.applicant__rent_applications USING btree (property_id);


--
-- Name: applicant__saved_forms_email_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX applicant__saved_forms_email_property_id_index ON public.applicant__saved_forms USING btree (email, property_id);


--
-- Name: applicant__vehicles_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX applicant__vehicles_application_id_index ON public.applicant__vehicles USING btree (application_id);


--
-- Name: accounting__checks accounting__checks_applicant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__checks
    ADD CONSTRAINT accounting__checks_applicant_id_fkey FOREIGN KEY (applicant_id) REFERENCES public.applicant__occupants(id) ON DELETE CASCADE;


--
-- Name: accounting__payments accounting__payments_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payments
    ADD CONSTRAINT accounting__payments_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE CASCADE;


--
-- Name: leases__forms leases__forms_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__forms
    ADD CONSTRAINT leases__forms_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE CASCADE;




--
-- Name: applicant__documents applicant__documents_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__documents
    ADD CONSTRAINT applicant__documents_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE CASCADE;



--
-- Name: applicant__emergency_contacts applicant__emergency_contacts_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__emergency_contacts
    ADD CONSTRAINT applicant__emergency_contacts_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE CASCADE;


--
-- Name: applicant__employments applicant__employments_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__employments
    ADD CONSTRAINT applicant__employments_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE CASCADE;


--
-- Name: applicant__employments applicant__employments_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__employments
    ADD CONSTRAINT applicant__employments_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.applicant__occupants(id) ON DELETE CASCADE;


--
-- Name: applicant__histories applicant__histories_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__histories
    ADD CONSTRAINT applicant__histories_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE CASCADE;


--
-- Name: applicant__incomes applicant__incomes_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__incomes
    ADD CONSTRAINT applicant__incomes_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE CASCADE;


--
-- Name: applicant__memos applicant__memos_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__memos
    ADD CONSTRAINT applicant__memos_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE CASCADE;


--
-- Name: applicant__move_ins applicant__move_ins_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__move_ins
    ADD CONSTRAINT applicant__move_ins_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE CASCADE;


--
-- Name: applicant__occupants applicant__occupants_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__occupants
    ADD CONSTRAINT applicant__occupants_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE CASCADE;


--
-- Name: applicant__pets applicant__pets_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__pets
    ADD CONSTRAINT applicant__pets_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE CASCADE;

--
-- Name: applicant__vehicles applicant__vehicles_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applicant__vehicles
    ADD CONSTRAINT applicant__vehicles_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE CASCADE;


--
-- Name: tenants__tenants tenants__tenants_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants__tenants
    ADD CONSTRAINT tenants__tenants_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applicant__rent_applications(id) ON DELETE SET NULL;

