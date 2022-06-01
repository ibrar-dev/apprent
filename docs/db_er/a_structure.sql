--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1 (Debian 12.1-1.pgdg100+1)
-- Dumped by pg_dump version 12.3

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

--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: insert_receipts(integer[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_receipts(lease_ids integer[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    receipt_ids      integer[];
    rent_account_ids integer[];
    extra_receipts   integer[];
BEGIN
    SELECT array_agg(a.id)
    into rent_account_ids
    FROM accounting__accounts a
    WHERE a.name = ANY (ARRAY ['Rent', 'HAPRent']);

    SELECT array_agg(r.id)
    into receipt_ids
    FROM accounting__receipts r
             LEFT JOIN accounting__charges c ON (c.id = r.charge_id OR c.id = r.concession_id)
             LEFT JOIN accounting__payments p ON p.id = r.payment_id
    WHERE c.lease_id = ANY (lease_ids)
       OR p.lease_id = ANY (lease_ids);

    DELETE FROM accounting__receipts r WHERE r.id = ANY (receipt_ids);

    WITH RECURSIVE
        rec(payment_id, concession_id, payment_balance, charge_id, charge_balance, amount, payments, charges, stop_date,
            start_date, stops, should_recurse, next_payments, next_charges)
            AS (
            SELECT CASE WHEN agg.payments[1][3] = 1 THEN agg.payments[1][1] END,
                   CASE WHEN agg.payments[1][3] = 2 THEN agg.payments[1][1] END,
                   GREATEST(agg.payments[1][2] - agg.charges[1][2], 0),
                   agg.charges[1][1],
                   GREATEST(agg.charges[1][2] - agg.payments[1][2], 0),
                   LEAST(agg.payments[1][2], agg.charges[1][2]),
                   CASE
                       WHEN agg.payments[1][2] <= agg.charges[1][2] THEN agg.payments[2:2147483647]
                       ELSE agg.payments END,
                   CASE
                       WHEN agg.charges[1][2] <= agg.payments[1][2] THEN agg.charges[2:2147483647]
                       ELSE agg.charges END,
                   to_timestamp(agg.stops[1])::date,
                   null::date,
                   agg.stops,
                   false,
                   CASE WHEN agg.payments[1][4] = agg.stops[1] THEN ARRAY []::numeric[] ELSE agg.payments[1:1] END,
                   CASE WHEN agg.charges[1][3] = agg.stops[1] THEN ARRAY []::numeric[] ELSE agg.charges[1:1] END
            FROM agg
            UNION ALL
            SELECT CASE WHEN rec.payments[1][3] = 1 THEN rec.payments[1][1] END,
                   CASE WHEN rec.payments[1][3] = 2 THEN rec.payments[1][1] END,
                   GREATEST(p_amount.amount - c_amount.amount, 0),
                   rec.charges[1][1],
                   GREATEST(c_amount.amount - p_amount.amount, 0),
                   LEAST(p_amount.amount, c_amount.amount),
                   CASE
                       WHEN is_last_row.t AND array_length(rec.stops, 1) > 0 AND
                            rec.payments[1][1] = (ARRAY [rec.payment_id, rec.concession_id])[rec.payments[1][3]]
                           THEN rec.next_payments || rec.payments[2:2147483647]
                       WHEN is_last_row.t AND array_length(rec.stops, 1) > 0 THEN rec.next_payments || rec.payments
                       WHEN p_amount.amount <= c_amount.amount THEN rec.payments[2:2147483647]
                       ELSE rec.payments END,
                   CASE
                       WHEN is_last_row.t AND array_length(rec.stops, 1) > 0 AND rec.charges[1][1] = rec.charge_id
                           THEN rec.next_charges || rec.charges[2:2147483647]
                       WHEN is_last_row.t AND array_length(rec.stops, 1) > 0 THEN rec.next_charges || rec.charges
                       WHEN c_amount.amount <= p_amount.amount THEN rec.charges[2:2147483647]
                       ELSE rec.charges END,
                   CASE WHEN rec.should_recurse THEN to_timestamp(rec.stops[2])::date ELSE rec.stop_date END,
                   CASE WHEN rec.should_recurse THEN rec.stop_date ELSE rec.start_date END,
                   CASE WHEN rec.should_recurse THEN rec.stops[2:2147483647] ELSE rec.stops END,
                   is_last_row.t,
                   CASE
                       WHEN is_last_row.t THEN ARRAY []::numeric[]
                       WHEN rec.payments[1][1] =
                            (ARRAY [rec.payment_id, rec.concession_id])[rec.payments[1][3]]
                           THEN rec.next_payments
                       WHEN rec.payments[1][4] = rec.stops[1] THEN rec.next_payments
                       ELSE rec.next_payments || rec.payments[1:1] END,
                   CASE
                       WHEN is_last_row.t THEN ARRAY []::numeric[]
                       WHEN rec.charges[1][1] = rec.charge_id THEN rec.next_charges
                       WHEN rec.charges[1][3] = rec.stops[1] THEN rec.next_charges
                       ELSE rec.next_charges || rec.charges[1:1] END
            FROM rec
                     JOIN LATERAL (SELECT CASE
                                              WHEN rec.charges[1][1] = rec.charge_id THEN rec.charge_balance
                                              ELSE rec.charges[1][2] END amount) c_amount
                          ON true
                     JOIN LATERAL (SELECT CASE
                                              WHEN rec.payments[1][1] =
                                                   (ARRAY [rec.payment_id, rec.concession_id])[rec.payments[1][3]]
                                                  THEN rec.payment_balance
                                              ELSE rec.payments[1][2] END amount) p_amount
                          ON true
                     JOIN LATERAL (SELECT CASE
                                              WHEN (array_length(rec.charges, 1) = 1 AND
                                                    c_amount.amount <= p_amount.amount) OR
                                                   (array_length(rec.payments, 1) = 1 AND
                                                    p_amount.amount <= c_amount.amount)
                                                  THEN
                                                  true
                                              ELSE false END t) is_last_row
                          ON true
            WHERE array_length(rec.charges, 1) > 0
              AND array_length(rec.payments, 1) > 0
        ),
        concessions AS (SELECT c.id, c.amount * -1, c.bill_date date, r.bill_date stop_date, 2 AS type
                        FROM accounting__charges c
                                 LEFT JOIN accounting__charges r ON c.reversal_id = r.id
                        WHERE c.amount < 0
                          AND c.lease_id = ANY (lease_ids)
                          AND c.reversal_id IS NULL
                          AND c.status != 'reversal'),
        payments AS (SELECT p.id, p.amount, p.inserted_at::date date, c.bill_date stop_date, 1 AS type
                     FROM accounting__payments p
                              LEFT JOIN accounting__charges c ON c.nsf_id = p.id
                     WHERE p.lease_id = ANY (lease_ids)
                       AND p.status != 'voided'),
        payers AS (
            SELECT *
            FROM payments
            WHERE payments.stop_date IS NULL
               OR payments.date != payments.stop_date
            UNION
            SELECT *
            FROM concessions
            WHERE concessions.stop_date IS NULL
               OR concessions.date != concessions.stop_date
        ),
        payments_concessions AS (SELECT array_agg(ARRAY [p.id, p.amount, p.type, EXTRACT(EPOCH FROM (p.stop_date))::integer]
                                                  ORDER BY EXTRACT(EPOCH FROM (p.date)) - p.type) p_ids,
                                        array_agg(EXTRACT(EPOCH FROM (p.stop_date))::integer)
                                        FILTER (WHERE p.stop_date IS NOT NULL)                    stops
                                 FROM payers p),
        charges AS (SELECT array_agg(ARRAY [c.id, c.amount, EXTRACT(EPOCH FROM (r.bill_date))::integer]
                                     ORDER BY c.bill_date,
                                         (CASE WHEN c.account_id = ANY (rent_account_ids) THEN 0 ELSE 1 END)
                               )                                  c_ids,
                           array_agg(EXTRACT(EPOCH FROM (r.bill_date))::integer)
                           FILTER (WHERE r.bill_date IS NOT NULL) stops
                    FROM accounting__charges c
                             LEFT JOIN accounting__charges r ON c.reversal_id = r.id
                    WHERE c.amount > 0
                      AND (c.bill_date != r.bill_date OR r.bill_date IS NULL)
                      AND c.lease_id = ANY (lease_ids)
                      AND c.nsf_id IS NULL
                      AND c.status != 'reversal'),
        agg AS (
            SELECT payments_concessions.p_ids                                                                     payments,
                   charges.c_ids                                                                                  charges,
                   ARRAY(SELECT DISTINCT unnest(array_cat(charges.stops, payments_concessions.stops)) ORDER BY 1) stops
            FROM payments_concessions
                     JOIN charges ON true
        )
    INSERT
    INTO accounting__receipts(payment_id, concession_id, charge_id, amount, start_date, stop_date, inserted_at,
                              updated_at)
    SELECT payment_id,
           concession_id,
           charge_id,
           amount,
           CASE WHEN bool_or(start_date IS NULL) THEN NULL ELSE min(start_date) END start_date,
           CASE WHEN bool_or(stop_date IS NULL) THEN NULL ELSE max(stop_date) END   stop_date,
           now()                                                                    inserted_at,
           now()                                                                    updated_at
    FROM rec
    WHERE charge_id IS NOT NULL
      AND (payment_id IS NOT NULL OR concession_id IS NOT NULL)
    GROUP BY payment_id, concession_id, charge_id, amount;

    SELECT array_agg(r.id)
    into extra_receipts
    FROM accounting__receipts r
             LEFT JOIN accounting__charges c ON (c.id = r.charge_id OR c.id = r.concession_id)
             LEFT JOIN accounting__payments p ON p.id = r.payment_id
             LEFT JOIN accounting__charges rev ON p.id = rev.nsf_id
             LEFT JOIN accounting__charges con ON con.id = r.concession_id
    WHERE (c.lease_id = ANY (lease_ids) OR p.lease_id = ANY (lease_ids))
      AND r.stop_date IS NULL
      AND (c.reversal_id IS NOT NULL OR con.reversal_id IS NOT NULL OR rev.nsf_id IS NOT NULL) ;

    DELETE FROM accounting__receipts r WHERE r.id = ANY (extra_receipts);
END
$$;


--
-- Name: post_charge_hook(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.post_charge_hook() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    lease_id         integer;
    ledger_lease_ids integer[];
BEGIN

    IF (TG_OP = 'DELETE')
    THEN
        lease_id = OLD.lease_id;
    ELSE
        lease_id = NEW.lease_id;
    END IF;

    SELECT ledgers.l_ids
    into ledger_lease_ids
    FROM (SELECT array_agg(l.id) l_ids
          FROM tenants__tenants AS t
                   INNER JOIN properties__occupancies AS p ON p.tenant_id = t.id
                   INNER JOIN leases__leases AS l ON p.lease_id = l.id
                   INNER JOIN properties__units AS u ON u.id = l.unit_id
          GROUP BY u.id, t.id) ledgers
    WHERE lease_id = ANY (ledgers.l_ids);

    PERFORM insert_receipts(ledger_lease_ids);

    RETURN NULL;
END
$$;


--
-- Name: post_payment_hook(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.post_payment_hook() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_lease_id     integer;
    ledger_lease_ids integer[];
BEGIN
    IF (TG_OP != 'DELETE' AND NEW.lease_id IS NULL)
    THEN
        SELECT target
        into new_lease_id
        FROM (
                 SELECT CASE
                            WHEN NEW.inserted_at < t.first_start_date THEN t.first_lease_id
                            WHEN NEW.inserted_at >= t.start_date THEN t.id
                            END target
                 FROM (
                          SELECT l.id,
                                 first_value(l.id) over (order by l.start_date)         first_lease_id,
                                 first_value(l.start_date) over (order by l.start_date) first_start_date,
                                 l.start_date
                          FROM tenants__tenants AS t
                                   INNER JOIN properties__occupancies AS p ON p.tenant_id = t.id
                                   INNER JOIN leases__leases AS l ON p.lease_id = l.id
                                   INNER JOIN properties__units AS u ON u.id = l.unit_id
                          WHERE p.tenant_id = NEW.tenant_id) t
                 ORDER BY t.start_date DESC) tt
        WHERE tt.target IS NOT NULL
        LIMIT 1;

        IF (new_lease_id IS NOT NULL) THEN
            UPDATE accounting__payments
            SET lease_id = new_lease_id
            WHERE accounting__payments.id = NEW.id;
        END IF;
    END IF;

    SELECT ledgers.l_ids
    into ledger_lease_ids
    FROM (SELECT array_agg(l.id) l_ids
          FROM tenants__tenants AS t
                   INNER JOIN properties__occupancies AS p ON p.tenant_id = t.id
                   INNER JOIN leases__leases AS l ON p.lease_id = l.id
                   INNER JOIN properties__units AS u ON u.id = l.unit_id
          GROUP BY u.id, t.id) ledgers WHERE coalesce(new_lease_id, NEW.lease_id) = ANY(ledgers.l_ids);

    PERFORM insert_receipts(ledger_lease_ids);

    RETURN NULL;
END
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounting__accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__accounts (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    is_credit boolean DEFAULT true NOT NULL,
    is_balance boolean DEFAULT true NOT NULL,
    is_cash boolean DEFAULT false NOT NULL,
    is_payable boolean DEFAULT false NOT NULL,
    num integer,
    charge_code character varying(255),
    source_id bigint,
    CONSTRAINT valid_number CHECK (((num >= 10000000) AND (num <= 99999999)))
);


--
-- Name: accounting__bank_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__bank_accounts (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    account_number character varying(255) NOT NULL,
    routing_number character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    bank_name character varying(255) NOT NULL,
    address jsonb DEFAULT '{}'::jsonb NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: accounting__bank_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__bank_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__bank_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__bank_accounts_id_seq OWNED BY public.accounting__bank_accounts.id;


--
-- Name: accounting__batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__batches (
    id bigint NOT NULL,
    property_id bigint NOT NULL,
    closed_by character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    date_closed date,
    memo text,
    bank_account_id bigint
);


--
-- Name: accounting__batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__batches_id_seq OWNED BY public.accounting__batches.id;


--
-- Name: accounting__budgets__imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__budgets__imports (
    id bigint NOT NULL,
    document_id bigint,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    admin_id bigint NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    errors jsonb DEFAULT '[]'::jsonb NOT NULL
);


--
-- Name: accounting__budgets__imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__budgets__imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__budgets__imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__budgets__imports_id_seq OWNED BY public.accounting__budgets__imports.id;


--
-- Name: accounting__budgets__lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__budgets__lines (
    id bigint NOT NULL,
    month date NOT NULL,
    amount numeric NOT NULL,
    closed boolean DEFAULT true NOT NULL,
    property_id bigint NOT NULL,
    admin_id bigint NOT NULL,
    account_id bigint NOT NULL,
    import_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    history jsonb DEFAULT '[]'::jsonb NOT NULL
);


--
-- Name: accounting__budgets__lines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__budgets__lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__budgets__lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__budgets__lines_id_seq OWNED BY public.accounting__budgets__lines.id;


--
-- Name: accounting__categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__categories (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    num integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    is_balance boolean DEFAULT false NOT NULL,
    max integer NOT NULL,
    in_approvals boolean DEFAULT false,
    total_only boolean DEFAULT false NOT NULL,
    CONSTRAINT valid_max_number CHECK (((max >= 10000000) AND (max <= 99999999))),
    CONSTRAINT valid_number CHECK (((num >= 10000000) AND (num <= 99999999)))
);


--
-- Name: accounting__categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__categories_id_seq OWNED BY public.accounting__categories.id;


--
-- Name: accounting__charge_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__charge_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__charge_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__charge_types_id_seq OWNED BY public.accounting__accounts.id;


--
-- Name: accounting__charges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__charges (
    id bigint NOT NULL,
    amount numeric(10,2) NOT NULL,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    charge_id bigint,
    lease_id bigint NOT NULL,
    account_id bigint NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    reversal_id bigint,
    bill_date date NOT NULL,
    admin character varying(255),
    post_month date NOT NULL,
    image_id bigint,
    nsf_id bigint,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT accounting_charges_non_zero CHECK ((amount <> (0)::numeric)),
    CONSTRAINT valid_post_month CHECK ((date_part('day'::text, post_month) = (1)::double precision))
);


--
-- Name: accounting__charges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__charges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__charges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__charges_id_seq OWNED BY public.accounting__charges.id;


--
-- Name: accounting__checks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__checks (
    id bigint NOT NULL,
    number integer NOT NULL,
    date date NOT NULL,
    bank_account_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    payee_id bigint,
    cleared boolean DEFAULT false NOT NULL,
    printed boolean DEFAULT false NOT NULL,
    tenant_id bigint,
    charge_id bigint,
    document_id bigint,
    amount_lang character varying(255),
    applicant_id bigint,
    lease_id bigint,
    amount numeric(10,2) NOT NULL,
    CONSTRAINT has_one_payee CHECK ((((payee_id IS NOT NULL) AND (tenant_id IS NULL) AND (applicant_id IS NULL)) OR ((tenant_id IS NOT NULL) AND (payee_id IS NULL) AND (applicant_id IS NULL)) OR ((applicant_id IS NOT NULL) AND (payee_id IS NULL) AND (tenant_id IS NULL)))),
    CONSTRAINT invoice_checks_have_no_charge CHECK (((payee_id IS NULL) OR (charge_id IS NULL))),
    CONSTRAINT tenant_checks_have_charge CHECK (((tenant_id IS NULL) OR (charge_id IS NOT NULL)))
);


--
-- Name: accounting__checks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__checks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__checks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__checks_id_seq OWNED BY public.accounting__checks.id;


--
-- Name: accounting__closings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__closings (
    id bigint NOT NULL,
    month date NOT NULL,
    closed_on date NOT NULL,
    admin_id bigint,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    type character varying(255) NOT NULL
);


--
-- Name: accounting__closings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__closings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__closings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__closings_id_seq OWNED BY public.accounting__closings.id;


--
-- Name: accounting__entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__entities (
    id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    property_id bigint NOT NULL,
    bank_account_id bigint NOT NULL
);


--
-- Name: accounting__entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__entities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__entities_id_seq OWNED BY public.accounting__entities.id;


--
-- Name: accounting__invoice_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__invoice_payments (
    id bigint NOT NULL,
    amount numeric NOT NULL,
    invoicing_id bigint NOT NULL,
    check_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    post_month date NOT NULL,
    account_id bigint,
    reconciliation_id bigint,
    CONSTRAINT valid_post_month CHECK ((date_part('day'::text, post_month) = (1)::double precision))
);


--
-- Name: accounting__invoice_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__invoice_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__invoice_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__invoice_payments_id_seq OWNED BY public.accounting__invoice_payments.id;


--
-- Name: accounting__invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__invoices (
    id bigint NOT NULL,
    post_month date NOT NULL,
    document character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    payee_id bigint NOT NULL,
    number character varying(255) NOT NULL,
    due_date date NOT NULL,
    notes text,
    payable_account_id bigint NOT NULL,
    date date NOT NULL,
    document_id bigint,
    amount numeric NOT NULL,
    purchase_order_id bigint,
    CONSTRAINT valid_post_month CHECK ((date_part('day'::text, post_month) = (1)::double precision))
);


--
-- Name: accounting__invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__invoices_id_seq OWNED BY public.accounting__invoices.id;


--
-- Name: accounting__invoicings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__invoicings (
    id bigint NOT NULL,
    invoice_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    amount numeric NOT NULL,
    notes text,
    property_id bigint NOT NULL,
    account_id bigint NOT NULL,
    item_id bigint
);


--
-- Name: accounting__invoicings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__invoicings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__invoicings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__invoicings_id_seq OWNED BY public.accounting__invoicings.id;


--
-- Name: accounting__journal_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__journal_entries (
    id bigint NOT NULL,
    amount numeric NOT NULL,
    account_id bigint NOT NULL,
    property_id bigint NOT NULL,
    page_id bigint NOT NULL,
    is_credit boolean DEFAULT false NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: accounting__journal_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__journal_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__journal_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__journal_entries_id_seq OWNED BY public.accounting__journal_entries.id;


--
-- Name: accounting__journal_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__journal_pages (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    date date NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    cash boolean DEFAULT false NOT NULL,
    accrual boolean DEFAULT false NOT NULL,
    post_month date NOT NULL,
    CONSTRAINT valid_post_month CHECK ((date_part('day'::text, post_month) = (1)::double precision))
);


--
-- Name: accounting__journal_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__journal_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__journal_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__journal_pages_id_seq OWNED BY public.accounting__journal_pages.id;


--
-- Name: accounting__payees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__payees (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    tax_form character varying(255),
    tax_id character varying(255),
    street character varying(255),
    city character varying(255),
    zip character varying(255),
    state character varying(255),
    email public.citext,
    phone character varying(255),
    due_period integer DEFAULT 30,
    consolidate_checks boolean DEFAULT true
);


--
-- Name: accounting__payees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__payees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__payees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__payees_id_seq OWNED BY public.accounting__payees.id;


--
-- Name: accounting__payment_nsfs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__payment_nsfs (
    id bigint NOT NULL,
    payment_id bigint NOT NULL,
    admin character varying(255) NOT NULL,
    proof character varying(255),
    reason character varying(255),
    date date NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    proof_id bigint
);


--
-- Name: accounting__payment_nsfs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__payment_nsfs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__payment_nsfs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__payment_nsfs_id_seq OWNED BY public.accounting__payment_nsfs.id;


--
-- Name: accounting__payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__payments (
    id bigint NOT NULL,
    amount numeric NOT NULL,
    transaction_id character varying(255) NOT NULL,
    source character varying(255) NOT NULL,
    surcharge numeric DEFAULT 0 NOT NULL,
    response jsonb DEFAULT '{}'::jsonb NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    tenant_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    status character varying(255) DEFAULT 'cleared'::character varying NOT NULL,
    edits jsonb DEFAULT '[]'::jsonb NOT NULL,
    payment_source_id bigint,
    property_id bigint NOT NULL,
    batch_id bigint,
    admin character varying(255),
    post_month date NOT NULL,
    image_id bigint,
    payer character varying(255),
    lease_id bigint,
    application_id bigint,
    memo character varying(255),
    reconciliation_id bigint,
    refund_date date,
    CONSTRAINT valid_post_month CHECK ((date_part('day'::text, post_month) = (1)::double precision))
);


--
-- Name: accounting__payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__payments_id_seq OWNED BY public.accounting__payments.id;


--
-- Name: accounting__receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__receipts (
    id bigint NOT NULL,
    amount numeric NOT NULL,
    charge_id bigint,
    payment_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    concession_id bigint,
    account_id bigint,
    start_date date,
    stop_date date,
    CONSTRAINT must_have_account CHECK (((charge_id IS NOT NULL) OR (account_id IS NOT NULL))),
    CONSTRAINT must_have_credit CHECK (((concession_id IS NOT NULL) OR (payment_id IS NOT NULL))),
    CONSTRAINT only_one_dest CHECK (((charge_id IS NULL) OR (account_id IS NULL))),
    CONSTRAINT only_one_source CHECK (((payment_id IS NULL) OR (concession_id IS NULL))),
    CONSTRAINT valid_date_range CHECK ((start_date < stop_date))
);


--
-- Name: accounting__receipts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__receipts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__receipts_id_seq OWNED BY public.accounting__receipts.id;


--
-- Name: accounting__reconciliation_postings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__reconciliation_postings (
    id bigint NOT NULL,
    end_date date,
    admin character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    bank_account_id bigint,
    total_deposits numeric,
    total_payments numeric,
    start_date date,
    is_posted boolean,
    document_id bigint
);


--
-- Name: accounting__reconciliation_postings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__reconciliation_postings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__reconciliation_postings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__reconciliation_postings_id_seq OWNED BY public.accounting__reconciliation_postings.id;


--
-- Name: accounting__reconciliations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__reconciliations (
    id bigint NOT NULL,
    clear_date date,
    memo character varying(255),
    payment_id bigint,
    check_id bigint,
    batch_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    journal_id bigint,
    reconciliation_posting_id bigint
);


--
-- Name: accounting__reconciliations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__reconciliations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__reconciliations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__reconciliations_id_seq OWNED BY public.accounting__reconciliations.id;


--
-- Name: accounting__registers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__registers (
    id bigint NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    property_id bigint NOT NULL,
    account_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    type character varying(255) DEFAULT 'cash'::character varying NOT NULL
);


--
-- Name: accounting__registers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__registers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__registers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__registers_id_seq OWNED BY public.accounting__registers.id;


--
-- Name: accounting__report_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__report_templates (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    groups jsonb DEFAULT '[]'::jsonb NOT NULL,
    is_balance boolean DEFAULT false NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: accounting__report_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__report_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__report_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__report_templates_id_seq OWNED BY public.accounting__report_templates.id;


--
-- Name: accounting__requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting__requests (
    id bigint NOT NULL,
    content text NOT NULL,
    pending boolean DEFAULT true NOT NULL,
    details jsonb DEFAULT '{}'::jsonb NOT NULL,
    payment_id bigint,
    charge_id bigint,
    admin_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: accounting__requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting__requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting__requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting__requests_id_seq OWNED BY public.accounting__requests.id;


--
-- Name: accounts__accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts__accounts (
    id bigint NOT NULL,
    encrypted_password character varying(255) NOT NULL,
    password_changed boolean DEFAULT false NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    receives_mailings boolean DEFAULT true NOT NULL,
    autopay boolean DEFAULT false NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    profile_pic character varying(255),
    push_token character varying(255),
    property_id bigint NOT NULL,
    username public.citext NOT NULL,
    profile_pic_id bigint
);


--
-- Name: accounts__accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts__accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts__accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts__accounts_id_seq OWNED BY public.accounts__accounts.id;


--
-- Name: accounts__autopays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts__autopays (
    id bigint NOT NULL,
    day integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    max_amount integer NOT NULL,
    account_id bigint NOT NULL,
    payment_source_id bigint NOT NULL,
    last_run date,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: accounts__autopays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts__autopays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts__autopays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts__autopays_id_seq OWNED BY public.accounts__autopays.id;


--
-- Name: settings__banks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings__banks (
    id bigint NOT NULL,
    routing character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: accounts__banks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts__banks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts__banks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts__banks_id_seq OWNED BY public.settings__banks.id;


--
-- Name: accounts__locks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts__locks (
    id bigint NOT NULL,
    reason character varying(255) NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    comments text,
    account_id bigint NOT NULL,
    admin_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: accounts__locks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts__locks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts__locks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts__locks_id_seq OWNED BY public.accounts__locks.id;


--
-- Name: accounts__logins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts__logins (
    id bigint NOT NULL,
    type character varying(255) NOT NULL,
    account_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: accounts__logins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts__logins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts__logins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts__logins_id_seq OWNED BY public.accounts__logins.id;


--
-- Name: accounts__payment_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts__payment_sources (
    id bigint NOT NULL,
    lock timestamp(0) without time zone,
    type character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    num1 text NOT NULL,
    num2 text NOT NULL,
    exp character varying(255),
    brand character varying(255) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    account_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: accounts__payment_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts__payment_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts__payment_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts__payment_sources_id_seq OWNED BY public.accounts__payment_sources.id;


--
-- Name: rewards__prizes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rewards__prizes (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    icon character varying(255),
    points integer NOT NULL,
    price numeric,
    url character varying(255) DEFAULT ''::character varying NOT NULL,
    promote boolean DEFAULT true NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    icon_id bigint
);


--
-- Name: accounts__prizes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts__prizes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts__prizes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts__prizes_id_seq OWNED BY public.rewards__prizes.id;


--
-- Name: rewards__purchases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rewards__purchases (
    id bigint NOT NULL,
    status character varying(255) NOT NULL,
    points integer NOT NULL,
    prize_id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    property_id bigint NOT NULL
);


--
-- Name: accounts__purchases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts__purchases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts__purchases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts__purchases_id_seq OWNED BY public.rewards__purchases.id;


--
-- Name: rewards__types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rewards__types (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    icon character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    points integer DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    monthly_max integer DEFAULT 1 NOT NULL,
    icon_id bigint
);


--
-- Name: accounts__reward_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts__reward_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts__reward_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts__reward_types_id_seq OWNED BY public.rewards__types.id;


--
-- Name: rewards__awards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rewards__awards (
    id bigint NOT NULL,
    amount integer NOT NULL,
    reason character varying(255) NOT NULL,
    created_by character varying(255) NOT NULL,
    reversal jsonb,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    type_id bigint NOT NULL
);


--
-- Name: accounts__rewards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts__rewards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts__rewards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts__rewards_id_seq OWNED BY public.rewards__awards.id;


--
-- Name: admins__actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__actions (
    id bigint NOT NULL,
    ip character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    params jsonb NOT NULL,
    admin_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    type character varying(255) DEFAULT 'create'::character varying NOT NULL
);


--
-- Name: admins__actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__actions_id_seq OWNED BY public.admins__actions.id;


--
-- Name: admins__admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__admins (
    id bigint NOT NULL,
    email public.citext NOT NULL,
    name character varying(255) NOT NULL,
    username public.citext NOT NULL,
    password_hash character varying(255) NOT NULL,
    uuid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    roles character varying(255)[] DEFAULT '{Admin}'::character varying[] NOT NULL,
    reset_pw boolean DEFAULT true NOT NULL
);


--
-- Name: admins__admins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__admins_id_seq OWNED BY public.admins__admins.id;


--
-- Name: admins__alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__alerts (
    id bigint NOT NULL,
    note character varying(255) NOT NULL,
    sender character varying(255) DEFAULT 'AppRent'::character varying NOT NULL,
    read boolean DEFAULT false NOT NULL,
    flag integer DEFAULT 1 NOT NULL,
    history jsonb NOT NULL,
    admin_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    attachment_id bigint
);


--
-- Name: admins__alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__alerts_id_seq OWNED BY public.admins__alerts.id;


--
-- Name: admins__approval_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__approval_attachments (
    id bigint NOT NULL,
    approval_id bigint NOT NULL,
    attachment_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: admins__approval_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__approval_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__approval_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__approval_attachments_id_seq OWNED BY public.admins__approval_attachments.id;


--
-- Name: admins__approval_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__approval_logs (
    id bigint NOT NULL,
    admin_id bigint NOT NULL,
    approval_id bigint NOT NULL,
    status character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    notes character varying(255),
    deleted boolean DEFAULT false
);


--
-- Name: admins__approval_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__approval_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__approval_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__approval_logs_id_seq OWNED BY public.admins__approval_logs.id;


--
-- Name: admins__approvals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__approvals (
    id bigint NOT NULL,
    admin_id bigint NOT NULL,
    property_id bigint NOT NULL,
    notes character varying(255),
    type character varying(255) NOT NULL,
    params jsonb NOT NULL,
    num character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    amount numeric
);


--
-- Name: admins__approvals_costs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__approvals_costs (
    id bigint NOT NULL,
    amount numeric DEFAULT 0 NOT NULL,
    approval_id bigint NOT NULL,
    category_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: admins__approvals_costs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__approvals_costs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__approvals_costs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__approvals_costs_id_seq OWNED BY public.admins__approvals_costs.id;


--
-- Name: admins__approvals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__approvals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__approvals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__approvals_id_seq OWNED BY public.admins__approvals.id;


--
-- Name: admins__approvals_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__approvals_notes (
    id bigint NOT NULL,
    admin_id bigint NOT NULL,
    approval_id bigint NOT NULL,
    note character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: admins__approvals_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__approvals_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__approvals_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__approvals_notes_id_seq OWNED BY public.admins__approvals_notes.id;


--
-- Name: admins__device_auths; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__device_auths (
    id bigint NOT NULL,
    device_id bigint NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: admins__device_auths_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__device_auths_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__device_auths_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__device_auths_id_seq OWNED BY public.admins__device_auths.id;


--
-- Name: admins__devices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__devices (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    public_cert text NOT NULL,
    private_cert text NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: admins__devices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__devices_id_seq OWNED BY public.admins__devices.id;


--
-- Name: admins__entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__entities (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    resources character varying(255)[] DEFAULT '{}'::character varying[] NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: admins__entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__entities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__entities_id_seq OWNED BY public.admins__entities.id;


--
-- Name: admins__messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__messages (
    id bigint NOT NULL,
    content text NOT NULL,
    category character varying(255) NOT NULL,
    admin_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: admins__messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__messages_id_seq OWNED BY public.admins__messages.id;


--
-- Name: admins__org_charts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__org_charts (
    id bigint NOT NULL,
    admin_id bigint,
    status character varying(255),
    path integer[] DEFAULT '{}'::integer[] NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: admins__org_charts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__org_charts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__org_charts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__org_charts_id_seq OWNED BY public.admins__org_charts.id;


--
-- Name: admins__permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__permissions (
    id bigint NOT NULL,
    admin_id bigint NOT NULL,
    entity_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: admins__permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__permissions_id_seq OWNED BY public.admins__permissions.id;


--
-- Name: admins__profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins__profiles (
    id bigint NOT NULL,
    bio text,
    admin_id bigint NOT NULL,
    image character varying(255),
    active boolean DEFAULT false,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    title character varying(255),
    image_id bigint
);


--
-- Name: admins__profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins__profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins__profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins__profiles_id_seq OWNED BY public.admins__profiles.id;


--
-- Name: chat__messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat__messages (
    id bigint NOT NULL,
    admin_id bigint NOT NULL,
    room_id bigint NOT NULL,
    attachment_id bigint,
    reply_id bigint,
    text character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: chat__messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat__messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat__messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat__messages_id_seq OWNED BY public.chat__messages.id;


--
-- Name: chat__read_receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat__read_receipts (
    id bigint NOT NULL,
    admin_id bigint NOT NULL,
    message_id bigint,
    room_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: chat__read_receipts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat__read_receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat__read_receipts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat__read_receipts_id_seq OWNED BY public.chat__read_receipts.id;


--
-- Name: chat__room_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat__room_members (
    id bigint NOT NULL,
    admin_id bigint NOT NULL,
    room_id bigint NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: chat__room_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat__room_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat__room_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat__room_members_id_seq OWNED BY public.chat__room_members.id;


--
-- Name: chat__rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat__rooms (
    id bigint NOT NULL,
    description character varying(255),
    name character varying(255),
    type character varying(255) DEFAULT 'Custom'::character varying NOT NULL,
    image_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: chat__rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat__rooms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat__rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat__rooms_id_seq OWNED BY public.chat__rooms.id;


--
-- Name: data__uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data__uploads (
    id bigint NOT NULL,
    uuid uuid NOT NULL,
    filename character varying(255) NOT NULL,
    size integer NOT NULL,
    content_type character varying(255) NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    is_loading boolean DEFAULT true NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    is_error boolean DEFAULT false NOT NULL
);


--
-- Name: data__upload_urls; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.data__upload_urls AS
 SELECT u.id,
    ((COALESCE(array_position(ARRAY[u.is_error, u.is_loading, u.is_public], true), 0) || ':'::text) || ((u.uuid || '/'::text) || (u.filename)::text)) AS url
   FROM public.data__uploads u;


--
-- Name: data__uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data__uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data__uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data__uploads_id_seq OWNED BY public.data__uploads.id;


--
-- Name: exports__categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exports__categories (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    admin_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: exports__categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exports__categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exports__categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exports__categories_id_seq OWNED BY public.exports__categories.id;


--
-- Name: exports__documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exports__documents (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    notes text,
    category_id bigint NOT NULL,
    document_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: exports__documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exports__documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exports__documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exports__documents_id_seq OWNED BY public.exports__documents.id;


--
-- Name: exports__recipients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exports__recipients (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    admin_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: exports__recipients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exports__recipients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exports__recipients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exports__recipients_id_seq OWNED BY public.exports__recipients.id;


--
-- Name: jobs__jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jobs__jobs (
    id bigint NOT NULL,
    schedule json DEFAULT '{}'::json NOT NULL,
    function character varying(255) NOT NULL,
    last_run integer,
    next_run integer,
    arguments json DEFAULT '[]'::json NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    CONSTRAINT day_conflict CHECK ((((schedule ->> 'day'::text) IS NULL) OR (((schedule ->> 'wday'::text) IS NULL) AND ((schedule ->> 'week'::text) IS NULL)))),
    CONSTRAINT day_invalid CHECK (((schedule ->> 'day'::text) <> '[]'::text)),
    CONSTRAINT hour_invalid CHECK (((schedule ->> 'hour'::text) <> '[]'::text)),
    CONSTRAINT minute_invalid CHECK (((schedule ->> 'minute'::text) <> '[]'::text)),
    CONSTRAINT month_invalid CHECK (((schedule ->> 'month'::text) <> '[]'::text)),
    CONSTRAINT wday_invalid CHECK (((schedule ->> 'wday'::text) <> '[]'::text)),
    CONSTRAINT week_invalid CHECK (((schedule ->> 'week'::text) <> '[]'::text)),
    CONSTRAINT year_invalid CHECK (((schedule ->> 'year'::text) <> '[]'::text))
);


--
-- Name: jobs__jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jobs__jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs__jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jobs__jobs_id_seq OWNED BY public.jobs__jobs.id;


--
-- Name: jobs__migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jobs__migrations (
    id bigint NOT NULL,
    module character varying(255) NOT NULL,
    function character varying(255) NOT NULL,
    arguments jsonb DEFAULT '{}'::jsonb NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: jobs__migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jobs__migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs__migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jobs__migrations_id_seq OWNED BY public.jobs__migrations.id;


--
-- Name: leases__custom_packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leases__custom_packages (
    id bigint NOT NULL,
    amount numeric NOT NULL,
    lease_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    notes jsonb DEFAULT '[]'::jsonb NOT NULL,
    renewal_package_id bigint NOT NULL
);


--
-- Name: leases__custom_packages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leases__custom_packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leases__custom_packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leases__custom_packages_id_seq OWNED BY public.leases__custom_packages.id;


--
-- Name: leases__forms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leases__forms (
    id bigint NOT NULL,
    lease_date date,
    unit_keys integer,
    mail_keys integer,
    other_keys integer,
    deposit_type character varying(255),
    deposit_value character varying(255),
    buy_out_fee numeric,
    concession_fee numeric,
    gate_access_remote boolean DEFAULT false NOT NULL,
    gate_access_code boolean DEFAULT false NOT NULL,
    gate_access_card boolean DEFAULT false NOT NULL,
    lost_card_fee boolean DEFAULT false NOT NULL,
    lost_remote_fee boolean DEFAULT false NOT NULL,
    code_change_fee boolean DEFAULT false NOT NULL,
    insurance_company character varying(255),
    monthly_discount numeric,
    one_time_concession numeric,
    concession_months date[] DEFAULT '{}'::date[],
    other_discount text,
    washer_rent numeric,
    washer_type character varying(255),
    washer_serial character varying(255),
    dryer_serial character varying(255),
    smart_fee numeric,
    waste_cost numeric,
    application_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    bug_inspection integer,
    bug_infestation integer,
    bug_disclosure text,
    fitness_card_numbers character varying(255)[] DEFAULT '{}'::character varying[],
    form_id character varying(255),
    signature_id character varying(255),
    status jsonb DEFAULT '{}'::jsonb NOT NULL,
    lease_id bigint,
    document_id bigint,
    signed boolean DEFAULT false NOT NULL,
    admin character varying(255) DEFAULT 'Property Admin'::character varying,
    CONSTRAINT must_have_assoc CHECK (((application_id IS NOT NULL) OR (lease_id IS NOT NULL)))
);


--
-- Name: leases__forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leases__forms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leases__forms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leases__forms_id_seq OWNED BY public.leases__forms.id;


--
-- Name: leases__leases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leases__leases (
    id bigint NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    unit_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    move_out_date date,
    expected_move_in date,
    actual_move_in date,
    notice_date date,
    deposit_amount numeric DEFAULT 0 NOT NULL,
    actual_move_out date,
    bluemoon_lease_id character varying(255),
    move_out_reason_id bigint,
    renewal_id bigint,
    document_id bigint,
    renewal_package_id bigint,
    closed boolean DEFAULT false NOT NULL,
    bluemoon_signature_id character varying(255),
    pending_bluemoon_signature_id character varying(255),
    pending_bluemoon_lease_id character varying(255),
    admin character varying(255),
    renewal_admin character varying(255),
    pending_default_lease_charges integer[] DEFAULT ARRAY[]::integer[],
    no_renewal boolean DEFAULT false,
    lease_date date,
    CONSTRAINT non_future_move_in CHECK ((actual_move_in <= now())),
    CONSTRAINT non_future_move_out CHECK ((actual_move_out <= now())),
    CONSTRAINT valid_duration CHECK ((start_date < end_date))
);


--
-- Name: leases__leases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leases__leases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leases__leases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leases__leases_id_seq OWNED BY public.leases__leases.id;


--
-- Name: leases__renewal_packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leases__renewal_packages (
    id bigint NOT NULL,
    min integer NOT NULL,
    max integer NOT NULL,
    base character varying(255) DEFAULT 'Market'::character varying NOT NULL,
    amount numeric NOT NULL,
    dollar boolean DEFAULT true NOT NULL,
    resident_selected boolean,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    renewal_period_id bigint,
    notes jsonb DEFAULT '[]'::jsonb
);


--
-- Name: leases__renewal_packages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leases__renewal_packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leases__renewal_packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leases__renewal_packages_id_seq OWNED BY public.leases__renewal_packages.id;


--
-- Name: leases__renewal_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leases__renewal_periods (
    id bigint NOT NULL,
    creator character varying(255) NOT NULL,
    approval_date date,
    approval_admin character varying(255),
    start_date date NOT NULL,
    end_date date NOT NULL,
    property_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    approval_request timestamp(0) without time zone,
    notes jsonb DEFAULT '[]'::jsonb
);


--
-- Name: leases__renewal_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leases__renewal_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leases__renewal_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leases__renewal_periods_id_seq OWNED BY public.leases__renewal_periods.id;


--
-- Name: leases__screenings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leases__screenings (
    id bigint NOT NULL,
    tenant_id bigint,
    first_name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    phone character varying(255) NOT NULL,
    email public.citext NOT NULL,
    city character varying(255) NOT NULL,
    income numeric NOT NULL,
    dob date NOT NULL,
    ssn text NOT NULL,
    state character varying(255) NOT NULL,
    street character varying(255) NOT NULL,
    zip character varying(255) NOT NULL,
    url character varying(255),
    order_id character varying(255),
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    decision character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    gateway_xml text,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    property_id bigint NOT NULL,
    person_id bigint,
    lease_id bigint,
    rent numeric NOT NULL,
    linked_orders character varying(255)[] DEFAULT '{}'::character varying[] NOT NULL,
    xml_data text[] DEFAULT '{}'::text[] NOT NULL,
    CONSTRAINT must_have_assoc CHECK (((person_id IS NOT NULL) OR (lease_id IS NOT NULL)))
);


--
-- Name: leases__screenings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leases__screenings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leases__screenings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leases__screenings_id_seq OWNED BY public.leases__screenings.id;


--
-- Name: maintenance__assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__assignments (
    id bigint NOT NULL,
    status character varying(255) NOT NULL,
    rating integer,
    completed_at timestamp(0) without time zone,
    confirmed_at timestamp(0) without time zone,
    tech_id bigint,
    order_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    materials jsonb DEFAULT '[]'::jsonb,
    tech_comments text,
    admin_id bigint,
    history jsonb DEFAULT '[]'::jsonb,
    callback_info jsonb,
    email jsonb,
    payee_id bigint
);


--
-- Name: maintenance__assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__assignments_id_seq OWNED BY public.maintenance__assignments.id;


--
-- Name: maintenance__card_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__card_items (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    notes text,
    scheduled date,
    completed date,
    card_id bigint NOT NULL,
    tech_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    completed_by character varying(255),
    status character varying(255),
    confirmation jsonb,
    vendor_id bigint
);


--
-- Name: maintenance__card_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__card_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__card_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__card_items_id_seq OWNED BY public.maintenance__card_items.id;


--
-- Name: maintenance__cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__cards (
    id bigint NOT NULL,
    items jsonb DEFAULT '{}'::jsonb NOT NULL,
    deadline date,
    lease_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    hidden boolean DEFAULT false,
    completion jsonb,
    admin character varying(255),
    priority integer,
    bypass_admin character varying(255),
    bypass_date timestamp(0) without time zone,
    unit_id bigint,
    CONSTRAINT must_have_unit_or_lease CHECK (((lease_id IS NOT NULL) OR (unit_id IS NOT NULL)))
);


--
-- Name: maintenance__cards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__cards_id_seq OWNED BY public.maintenance__cards.id;


--
-- Name: maintenance__categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__categories (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    path integer[] DEFAULT '{}'::integer[] NOT NULL,
    parent_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    third_party boolean DEFAULT false
);


--
-- Name: maintenance__categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__categories_id_seq OWNED BY public.maintenance__categories.id;


--
-- Name: maintenance__timecards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__timecards (
    id bigint NOT NULL,
    start_location jsonb,
    tech_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    start_ts bigint NOT NULL,
    end_ts bigint,
    end_location jsonb
);


--
-- Name: maintenance__clocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__clocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__clocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__clocks_id_seq OWNED BY public.maintenance__timecards.id;


--
-- Name: maintenance__inventory_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__inventory_logs (
    id bigint NOT NULL,
    old integer NOT NULL,
    new integer NOT NULL,
    source character varying(255) NOT NULL,
    material_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: maintenance__inventory_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__inventory_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__inventory_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__inventory_logs_id_seq OWNED BY public.maintenance__inventory_logs.id;


--
-- Name: maintenance__jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__jobs (
    id bigint NOT NULL,
    property_id bigint NOT NULL,
    tech_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: maintenance__jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__jobs_id_seq OWNED BY public.maintenance__jobs.id;


--
-- Name: materials__logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials__logs (
    id bigint NOT NULL,
    quantity integer,
    admin character varying(255),
    property_id bigint,
    stock_id bigint,
    material_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    returned jsonb
);


--
-- Name: maintenance__material_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__material_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__material_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__material_logs_id_seq OWNED BY public.materials__logs.id;


--
-- Name: materials__types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials__types (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: maintenance__material_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__material_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__material_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__material_types_id_seq OWNED BY public.materials__types.id;


--
-- Name: materials__materials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials__materials (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    cost numeric DEFAULT 0 NOT NULL,
    inventory integer DEFAULT 0 NOT NULL,
    desired integer DEFAULT 0 NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    type_id bigint NOT NULL,
    ref_number character varying(255) NOT NULL,
    per_unit integer DEFAULT 1 NOT NULL,
    image character varying(255),
    location jsonb,
    image_id bigint
);


--
-- Name: maintenance__materials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__materials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__materials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__materials_id_seq OWNED BY public.materials__materials.id;


--
-- Name: materials__orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials__orders (
    id bigint NOT NULL,
    number character varying(255) NOT NULL,
    status character varying(255) NOT NULL,
    tax numeric DEFAULT 0 NOT NULL,
    shipping numeric DEFAULT 0 NOT NULL,
    history jsonb NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: maintenance__materials_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__materials_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__materials_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__materials_orders_id_seq OWNED BY public.materials__orders.id;


--
-- Name: materials__order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials__order_items (
    id bigint NOT NULL,
    quantity integer,
    status character varying(255) NOT NULL,
    cost numeric DEFAULT 0 NOT NULL,
    material_id bigint NOT NULL,
    order_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: maintenance__materials_orders_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__materials_orders_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__materials_orders_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__materials_orders_items_id_seq OWNED BY public.materials__order_items.id;


--
-- Name: maintenance__notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__notes (
    id bigint NOT NULL,
    text text,
    image character varying(255),
    tenant_id bigint,
    admin_id bigint,
    order_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    tech_id bigint,
    attachment_id bigint,
    CONSTRAINT must_have_assigner CHECK (((admin_id IS NOT NULL) OR (tenant_id IS NOT NULL) OR (tech_id IS NOT NULL))),
    CONSTRAINT must_have_body CHECK (((text IS NOT NULL) OR (image IS NOT NULL) OR (attachment_id IS NOT NULL)))
);


--
-- Name: maintenance__notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__notes_id_seq OWNED BY public.maintenance__notes.id;


--
-- Name: maintenance__offers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__offers (
    id bigint NOT NULL,
    tech_id bigint NOT NULL,
    order_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: maintenance__offers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__offers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__offers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__offers_id_seq OWNED BY public.maintenance__offers.id;


--
-- Name: maintenance__open_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__open_history (
    id bigint NOT NULL,
    open integer NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: maintenance__open_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__open_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__open_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__open_history_id_seq OWNED BY public.maintenance__open_history.id;


--
-- Name: maintenance__orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__orders (
    id bigint NOT NULL,
    tenant_id bigint,
    unit_id bigint,
    has_pet boolean DEFAULT false NOT NULL,
    entry_allowed boolean DEFAULT false NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    category_id bigint NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    uuid uuid,
    ticket character varying(255) DEFAULT 'UNKNOWN'::character varying NOT NULL,
    cancellation jsonb,
    card_item_id bigint,
    no_access jsonb[] DEFAULT ARRAY[]::jsonb[],
    created_by character varying(255)
);


--
-- Name: maintenance__orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__orders_id_seq OWNED BY public.maintenance__orders.id;


--
-- Name: maintenance__paid_time; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__paid_time (
    id bigint NOT NULL,
    hours integer NOT NULL,
    date date,
    approved boolean DEFAULT false,
    reason character varying(255),
    tech_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: maintenance__paid_time_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__paid_time_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__paid_time_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__paid_time_id_seq OWNED BY public.maintenance__paid_time.id;


--
-- Name: maintenance__parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__parts (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    order_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: maintenance__parts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__parts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__parts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__parts_id_seq OWNED BY public.maintenance__parts.id;


--
-- Name: maintenance__presence_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__presence_logs (
    id bigint NOT NULL,
    present boolean DEFAULT false NOT NULL,
    tech_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: maintenance__presence_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__presence_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__presence_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__presence_logs_id_seq OWNED BY public.maintenance__presence_logs.id;


--
-- Name: maintenance__recurring_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__recurring_orders (
    id bigint NOT NULL,
    schedule jsonb NOT NULL,
    params jsonb NOT NULL,
    name character varying(255) NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    last_run integer,
    next_run integer,
    admin_id bigint
);


--
-- Name: maintenance__recurring_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__recurring_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__recurring_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__recurring_orders_id_seq OWNED BY public.maintenance__recurring_orders.id;


--
-- Name: maintenance__skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__skills (
    id bigint NOT NULL,
    tech_id bigint NOT NULL,
    category_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: maintenance__skills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__skills_id_seq OWNED BY public.maintenance__skills.id;


--
-- Name: materials__stocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials__stocks (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    image character varying(255),
    warehouse_id bigint,
    image_id bigint
);


--
-- Name: maintenance__stocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__stocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__stocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__stocks_id_seq OWNED BY public.materials__stocks.id;


--
-- Name: maintenance__techs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance__techs (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    email public.citext NOT NULL,
    phone_number character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    pass_code uuid,
    identifier uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    type character varying(255) DEFAULT 'Tech'::character varying NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    push_token character varying(255),
    image character varying(255),
    can_edit boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    image_id bigint
);


--
-- Name: maintenance__techs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maintenance__techs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance__techs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance__techs_id_seq OWNED BY public.maintenance__techs.id;


--
-- Name: materials__inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials__inventory (
    id bigint NOT NULL,
    inventory integer DEFAULT 0 NOT NULL,
    stock_id bigint NOT NULL,
    material_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: materials__inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.materials__inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: materials__inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.materials__inventory_id_seq OWNED BY public.materials__inventory.id;


--
-- Name: materials__toolbox_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials__toolbox_items (
    id bigint NOT NULL,
    admin character varying(255),
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    history jsonb,
    stock_id bigint NOT NULL,
    material_id bigint NOT NULL,
    tech_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    assignment_id bigint,
    returned_by character varying(255),
    return_stock bigint
);


--
-- Name: materials__toolbox_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.materials__toolbox_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: materials__toolbox_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.materials__toolbox_items_id_seq OWNED BY public.materials__toolbox_items.id;


--
-- Name: materials__warehouses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materials__warehouses (
    id bigint NOT NULL,
    name character varying(255),
    image character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    image_id bigint
);


--
-- Name: materials__warehouses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.materials__warehouses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: materials__warehouses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.materials__warehouses_id_seq OWNED BY public.materials__warehouses.id;


--
-- Name: messaging__emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messaging__emails (
    id bigint NOT NULL,
    subject character varying(255) NOT NULL,
    body character varying(255) NOT NULL,
    "to" character varying(255) NOT NULL,
    "from" character varying(255) NOT NULL,
    attachments character varying(255)[] DEFAULT '{}'::character varying[] NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    body_id bigint
);


--
-- Name: messaging__emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messaging__emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messaging__emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messaging__emails_id_seq OWNED BY public.messaging__emails.id;


--
-- Name: messaging__inboxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messaging__inboxes (
    id bigint NOT NULL,
    admin_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: messaging__inboxes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messaging__inboxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messaging__inboxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messaging__inboxes_id_seq OWNED BY public.messaging__inboxes.id;


--
-- Name: messaging__mail_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messaging__mail_addresses (
    id bigint NOT NULL,
    address character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: messaging__mail_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messaging__mail_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messaging__mail_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messaging__mail_addresses_id_seq OWNED BY public.messaging__mail_addresses.id;


--
-- Name: messaging__mail_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messaging__mail_templates (
    id bigint NOT NULL,
    subject character varying(255) NOT NULL,
    body text NOT NULL,
    creator text NOT NULL,
    history jsonb,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: messaging__mail_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messaging__mail_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messaging__mail_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messaging__mail_templates_id_seq OWNED BY public.messaging__mail_templates.id;


--
-- Name: messaging__mailings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messaging__mailings (
    id bigint NOT NULL,
    send_at jsonb,
    recipients jsonb NOT NULL,
    subject character varying(255) NOT NULL,
    body text NOT NULL,
    property_ids jsonb NOT NULL,
    sender text NOT NULL,
    next_run integer,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    attachments character varying(255)[] DEFAULT '{}'::character varying[] NOT NULL
);


--
-- Name: messaging__mailings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messaging__mailings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messaging__mailings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messaging__mailings_id_seq OWNED BY public.messaging__mailings.id;


--
-- Name: messaging__message_threads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messaging__message_threads (
    id bigint NOT NULL,
    inbox_id bigint NOT NULL,
    "from" character varying(255) NOT NULL,
    "to" character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    name character varying(255),
    is_spam boolean DEFAULT false NOT NULL,
    is_starred boolean DEFAULT false NOT NULL,
    is_approved boolean DEFAULT false NOT NULL
);


--
-- Name: messaging__message_threads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messaging__message_threads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messaging__message_threads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messaging__message_threads_id_seq OWNED BY public.messaging__message_threads.id;


--
-- Name: messaging__messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messaging__messages (
    id bigint NOT NULL,
    body text NOT NULL,
    index integer NOT NULL,
    is_reply boolean NOT NULL,
    message_thread_id bigint NOT NULL,
    attachments character varying(255)[] DEFAULT ARRAY[]::character varying[],
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: messaging__messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messaging__messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messaging__messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messaging__messages_id_seq OWNED BY public.messaging__messages.id;


--
-- Name: messaging__property_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messaging__property_templates (
    id bigint NOT NULL,
    property_id bigint NOT NULL,
    template_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: messaging__property_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messaging__property_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messaging__property_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messaging__property_templates_id_seq OWNED BY public.messaging__property_templates.id;


--
-- Name: messaging__routes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messaging__routes (
    id bigint NOT NULL,
    mail_address_id bigint NOT NULL,
    inbox_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: messaging__routes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messaging__routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messaging__routes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messaging__routes_id_seq OWNED BY public.messaging__routes.id;


--
-- Name: properties__admin_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__admin_documents (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    creator character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    document_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__admin_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__admin_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__admin_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__admin_documents_id_seq OWNED BY public.properties__admin_documents.id;


--
-- Name: properties__charges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__charges (
    id bigint NOT NULL,
    amount numeric NOT NULL,
    schedule jsonb DEFAULT '{}'::jsonb NOT NULL,
    lease_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    account_id bigint NOT NULL,
    from_date date,
    to_date date,
    next_bill_date date NOT NULL,
    edits jsonb DEFAULT '[]'::jsonb NOT NULL,
    CONSTRAINT lease_charges_valid_dates CHECK (((from_date IS NULL) OR (to_date IS NULL) OR (from_date < to_date))),
    CONSTRAINT leases_charges_non_zero CHECK ((amount <> (0)::numeric)),
    CONSTRAINT properties_charges_non_zero CHECK ((amount <> (0)::numeric))
);


--
-- Name: properties__charges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__charges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__charges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__charges_id_seq OWNED BY public.properties__charges.id;


--
-- Name: properties__documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__documents (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    type character varying(255) NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    document_id bigint NOT NULL
);


--
-- Name: properties__documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__documents_id_seq OWNED BY public.properties__documents.id;


--
-- Name: properties__evictions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__evictions (
    id bigint NOT NULL,
    file_date date NOT NULL,
    court_date date,
    notes text,
    lease_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__evictions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__evictions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__evictions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__evictions_id_seq OWNED BY public.properties__evictions.id;


--
-- Name: properties__features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__features (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    price numeric NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    start_date date,
    stop_date date
);


--
-- Name: properties__features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__features_id_seq OWNED BY public.properties__features.id;


--
-- Name: properties__floor_plan_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__floor_plan_features (
    id bigint NOT NULL,
    feature_id bigint NOT NULL,
    floor_plan_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__floor_plan_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__floor_plan_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__floor_plan_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__floor_plan_features_id_seq OWNED BY public.properties__floor_plan_features.id;


--
-- Name: properties__floor_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__floor_plans (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__floor_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__floor_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__floor_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__floor_plans_id_seq OWNED BY public.properties__floor_plans.id;


--
-- Name: properties__insurances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__insurances (
    id bigint NOT NULL,
    title character varying(255),
    canceled date,
    reinstate date,
    number character varying(255) NOT NULL,
    amount numeric NOT NULL,
    company character varying(255) NOT NULL,
    begins date NOT NULL,
    ends date NOT NULL,
    renewal boolean DEFAULT false NOT NULL,
    legal_liability boolean DEFAULT false NOT NULL,
    satisfies_move_in boolean DEFAULT false NOT NULL,
    interested_party boolean DEFAULT false NOT NULL,
    pet_endorsement boolean DEFAULT false NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__insurances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__insurances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__insurances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__insurances_id_seq OWNED BY public.properties__insurances.id;


--
-- Name: properties__letter_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__letter_templates (
    id bigint NOT NULL,
    property_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    body text NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__letter_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__letter_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__letter_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__letter_templates_id_seq OWNED BY public.properties__letter_templates.id;


--
-- Name: properties__occupancies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__occupancies (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    lease_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__occupancies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__occupancies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__occupancies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__occupancies_id_seq OWNED BY public.properties__occupancies.id;


--
-- Name: properties__occupants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__occupants (
    id bigint NOT NULL,
    lease_id bigint NOT NULL,
    first_name character varying(255) NOT NULL,
    middle_name character varying(255),
    last_name character varying(255) NOT NULL,
    phone character varying(255),
    email public.citext,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__occupants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__occupants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__occupants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__occupants_id_seq OWNED BY public.properties__occupants.id;


--
-- Name: properties__packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__packages (
    id bigint NOT NULL,
    status character varying(255) DEFAULT 'Pending'::character varying NOT NULL,
    condition character varying(255),
    last_emailed date,
    type character varying(255),
    tracking_number character varying(255),
    carrier character varying(255) DEFAULT 'Other'::character varying NOT NULL,
    name character varying(255),
    unit_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    reason character varying(255),
    admin character varying(255) NOT NULL,
    notes character varying(255),
    tenant_id bigint
);


--
-- Name: properties__packages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__packages_id_seq OWNED BY public.properties__packages.id;


--
-- Name: properties__phone__lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__phone__lines (
    id bigint NOT NULL,
    number character varying(255) NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    CONSTRAINT valid_phone_number CHECK (((number)::text ~* '\(\d{3}\) \d{3}-\d{4}'::text))
);


--
-- Name: properties__phone__lines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__phone__lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__phone__lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__phone__lines_id_seq OWNED BY public.properties__phone__lines.id;


--
-- Name: properties__processors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__processors (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    keys text[] DEFAULT '{}'::text[] NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__processors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__processors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__processors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__processors_id_seq OWNED BY public.properties__processors.id;


--
-- Name: properties__properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__properties (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    logo character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    address json DEFAULT '{}'::json NOT NULL,
    terms text DEFAULT ''::text NOT NULL,
    stock_id bigint,
    lat numeric,
    lng numeric,
    social jsonb DEFAULT '{}'::jsonb NOT NULL,
    phone character varying(255),
    website character varying(255),
    icon character varying(255),
    banner character varying(255),
    primary_color character varying(255) DEFAULT '#6ECD0B'::character varying NOT NULL,
    logo_id bigint,
    icon_id bigint,
    banner_id bigint,
    group_email character varying(255),
    region character varying(255) DEFAULT ''::character varying NOT NULL,
    region_id bigint
);


--
-- Name: properties__properties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__properties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__properties_id_seq OWNED BY public.properties__properties.id;


--
-- Name: properties__property_admin_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__property_admin_documents (
    id bigint NOT NULL,
    property_id bigint NOT NULL,
    admin_document_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__property_admin_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__property_admin_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__property_admin_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__property_admin_documents_id_seq OWNED BY public.properties__property_admin_documents.id;


--
-- Name: properties__recurring_letters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__recurring_letters (
    id bigint NOT NULL,
    letter_template_id bigint NOT NULL,
    admin_id bigint NOT NULL,
    resident_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    schedule json DEFAULT '{}'::json NOT NULL,
    active boolean DEFAULT false NOT NULL,
    last_run integer,
    next_run integer,
    notify boolean NOT NULL,
    visible boolean NOT NULL,
    name character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__recurring_letters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__recurring_letters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__recurring_letters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__recurring_letters_id_seq OWNED BY public.properties__recurring_letters.id;


--
-- Name: properties__regions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__regions (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    regional_supervisor_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__regions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__regions_id_seq OWNED BY public.properties__regions.id;


--
-- Name: properties__resident_event_attendances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__resident_event_attendances (
    id bigint NOT NULL,
    resident_event_id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__resident_event_attendances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__resident_event_attendances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__resident_event_attendances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__resident_event_attendances_id_seq OWNED BY public.properties__resident_event_attendances.id;


--
-- Name: properties__resident_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__resident_events (
    id bigint NOT NULL,
    location character varying(255),
    name character varying(255) NOT NULL,
    info text,
    date date NOT NULL,
    start_time integer NOT NULL,
    end_time integer,
    admin character varying(255) NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    image character varying(255),
    attachment character varying(255),
    attachment_id bigint,
    image_id bigint
);


--
-- Name: properties__resident_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__resident_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__resident_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__resident_events_id_seq OWNED BY public.properties__resident_events.id;


--
-- Name: properties__scopings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__scopings (
    id bigint NOT NULL,
    entity_id bigint NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__scopings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__scopings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__scopings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__scopings_id_seq OWNED BY public.properties__scopings.id;


--
-- Name: properties__settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__settings (
    id bigint NOT NULL,
    application_fee numeric DEFAULT 50 NOT NULL,
    admin_fee numeric DEFAULT 150 NOT NULL,
    area_rate numeric DEFAULT 1 NOT NULL,
    notice_period integer DEFAULT 30 NOT NULL,
    grace_period integer DEFAULT 7 NOT NULL,
    mtm_multiplier numeric DEFAULT 1 NOT NULL,
    late_fee_threshold numeric DEFAULT 50 NOT NULL,
    late_fee_amount numeric DEFAULT 50 NOT NULL,
    late_fee_type character varying(255) DEFAULT '$'::character varying NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    daily_late_fee_addition numeric DEFAULT 0 NOT NULL,
    rewards boolean DEFAULT true,
    nsf_fee integer DEFAULT 50 NOT NULL,
    mtm_fee integer DEFAULT 250 NOT NULL,
    renewal_overage_threshold integer DEFAULT 25 NOT NULL,
    applicant_info_visible boolean DEFAULT true NOT NULL,
    accepts_partial_payments boolean DEFAULT true NOT NULL,
    instant_screen boolean DEFAULT false NOT NULL,
    applications boolean DEFAULT true NOT NULL,
    tours boolean DEFAULT true NOT NULL,
    default_bank_account_id bigint,
    verification_form text DEFAULT ''::text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: properties__settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__settings_id_seq OWNED BY public.properties__settings.id;


--
-- Name: properties__unit_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__unit_features (
    id bigint NOT NULL,
    unit_id bigint,
    feature_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: properties__unit_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__unit_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__unit_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__unit_features_id_seq OWNED BY public.properties__unit_features.id;


--
-- Name: properties__units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__units (
    id bigint NOT NULL,
    number character varying(255) NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    uuid uuid,
    area integer DEFAULT 0 NOT NULL,
    floor_plan_id bigint,
    status character varying(255),
    address jsonb
);


--
-- Name: properties__units_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__units_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__units_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__units_id_seq OWNED BY public.properties__units.id;


--
-- Name: properties__visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties__visits (
    id bigint NOT NULL,
    description text NOT NULL,
    admin character varying(255) NOT NULL,
    tenant_id bigint NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    delinquency timestamp(0) without time zone
);


--
-- Name: properties__visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.properties__visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: properties__visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.properties__visits_id_seq OWNED BY public.properties__visits.id;


--
-- Name: prospects__closures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prospects__closures (
    id bigint NOT NULL,
    date date NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    reason character varying(255) NOT NULL,
    admin character varying(255) NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    CONSTRAINT closures_end_after_start CHECK ((start_time < end_time))
);


--
-- Name: prospects__closures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prospects__closures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prospects__closures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prospects__closures_id_seq OWNED BY public.prospects__closures.id;


--
-- Name: prospects__memos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prospects__memos (
    id bigint NOT NULL,
    admin character varying(255),
    notes character varying(255),
    prospect_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: prospects__memos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prospects__memos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prospects__memos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prospects__memos_id_seq OWNED BY public.prospects__memos.id;


--
-- Name: prospects__openings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prospects__openings (
    id bigint NOT NULL,
    wday integer NOT NULL,
    showing_slots integer DEFAULT 1 NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: prospects__openings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prospects__openings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prospects__openings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prospects__openings_id_seq OWNED BY public.prospects__openings.id;


--
-- Name: prospects__prospects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prospects__prospects (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    contact_date date,
    move_in date,
    next_follow_up date,
    phone character varying(255),
    contact_type character varying(255),
    contact_result character varying(255),
    admin_id bigint,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    traffic_source_id bigint,
    email public.citext,
    notes text,
    address jsonb DEFAULT '{}'::jsonb NOT NULL,
    floor_plan_id bigint,
    referral character varying(255)
);


--
-- Name: prospects__prospects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prospects__prospects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prospects__prospects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prospects__prospects_id_seq OWNED BY public.prospects__prospects.id;


--
-- Name: prospects__referral; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prospects__referral (
    id bigint NOT NULL,
    referrer character varying(255) NOT NULL,
    ip_address character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: prospects__referral_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prospects__referral_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prospects__referral_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prospects__referral_id_seq OWNED BY public.prospects__referral.id;


--
-- Name: prospects__showings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prospects__showings (
    id bigint NOT NULL,
    date date NOT NULL,
    prospect_id bigint NOT NULL,
    property_id bigint NOT NULL,
    unit_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    cancellation date
);


--
-- Name: prospects__showings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prospects__showings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prospects__showings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prospects__showings_id_seq OWNED BY public.prospects__showings.id;


--
-- Name: prospects__traffic_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prospects__traffic_sources (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    type character varying(255)
);


--
-- Name: prospects__traffic_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prospects__traffic_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prospects__traffic_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prospects__traffic_sources_id_seq OWNED BY public.prospects__traffic_sources.id;


--
-- Name: rent_apply__documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rent_apply__documents (
    id bigint NOT NULL,
    type character varying(255) NOT NULL,
    application_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    url_id bigint NOT NULL
);


--
-- Name: rent_apply__documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rent_apply__documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rent_apply__documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rent_apply__documents_id_seq OWNED BY public.rent_apply__documents.id;


--
-- Name: rent_apply__emergency_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rent_apply__emergency_contacts (
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
-- Name: rent_apply__emergency_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rent_apply__emergency_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rent_apply__emergency_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rent_apply__emergency_contacts_id_seq OWNED BY public.rent_apply__emergency_contacts.id;


--
-- Name: rent_apply__employments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rent_apply__employments (
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
-- Name: rent_apply__employments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rent_apply__employments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rent_apply__employments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rent_apply__employments_id_seq OWNED BY public.rent_apply__employments.id;


--
-- Name: rent_apply__histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rent_apply__histories (
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
-- Name: rent_apply__histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rent_apply__histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rent_apply__histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rent_apply__histories_id_seq OWNED BY public.rent_apply__histories.id;


--
-- Name: rent_apply__incomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rent_apply__incomes (
    id bigint NOT NULL,
    description character varying(255) NOT NULL,
    salary numeric NOT NULL,
    application_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: rent_apply__incomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rent_apply__incomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rent_apply__incomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rent_apply__incomes_id_seq OWNED BY public.rent_apply__incomes.id;


--
-- Name: rent_apply__memos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rent_apply__memos (
    id bigint NOT NULL,
    note character varying(255) NOT NULL,
    application_id bigint NOT NULL,
    admin_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: rent_apply__memos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rent_apply__memos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rent_apply__memos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rent_apply__memos_id_seq OWNED BY public.rent_apply__memos.id;


--
-- Name: rent_apply__move_ins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rent_apply__move_ins (
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
-- Name: rent_apply__move_ins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rent_apply__move_ins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rent_apply__move_ins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rent_apply__move_ins_id_seq OWNED BY public.rent_apply__move_ins.id;


--
-- Name: rent_apply__persons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rent_apply__persons (
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
-- Name: rent_apply__persons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rent_apply__persons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rent_apply__persons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rent_apply__persons_id_seq OWNED BY public.rent_apply__persons.id;


--
-- Name: rent_apply__pets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rent_apply__pets (
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
-- Name: rent_apply__pets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rent_apply__pets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rent_apply__pets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rent_apply__pets_id_seq OWNED BY public.rent_apply__pets.id;


--
-- Name: rent_apply__rent_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rent_apply__rent_applications (
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
-- Name: rent_apply__rent_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rent_apply__rent_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rent_apply__rent_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rent_apply__rent_applications_id_seq OWNED BY public.rent_apply__rent_applications.id;


--
-- Name: rent_apply__saved_forms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rent_apply__saved_forms (
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
-- Name: rent_apply__saved_forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rent_apply__saved_forms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rent_apply__saved_forms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rent_apply__saved_forms_id_seq OWNED BY public.rent_apply__saved_forms.id;


--
-- Name: rent_apply__vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rent_apply__vehicles (
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
-- Name: rent_apply__vehicles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rent_apply__vehicles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rent_apply__vehicles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rent_apply__vehicles_id_seq OWNED BY public.rent_apply__vehicles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: settings__damages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings__damages (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: settings__damages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings__damages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings__damages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings__damages_id_seq OWNED BY public.settings__damages.id;


--
-- Name: settings__move_out_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings__move_out_reasons (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: settings__move_out_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings__move_out_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings__move_out_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings__move_out_reasons_id_seq OWNED BY public.settings__move_out_reasons.id;


--
-- Name: social__blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social__blocks (
    id bigint NOT NULL,
    tenant_id bigint,
    blockee_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: social__blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social__blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social__blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social__blocks_id_seq OWNED BY public.social__blocks.id;


--
-- Name: social__posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social__posts (
    id bigint NOT NULL,
    text text,
    history jsonb,
    tenant_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    property_id bigint,
    visible boolean DEFAULT true NOT NULL
);


--
-- Name: social__posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social__posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social__posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social__posts_id_seq OWNED BY public.social__posts.id;


--
-- Name: social__posts_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social__posts_likes (
    id bigint NOT NULL,
    tenant_id bigint,
    post_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: social__posts_likes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social__posts_likes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social__posts_likes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social__posts_likes_id_seq OWNED BY public.social__posts_likes.id;


--
-- Name: social__reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social__reports (
    id bigint NOT NULL,
    admin_id bigint,
    tenant_id bigint,
    post_id bigint,
    reason character varying(255) DEFAULT false,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: social__reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social__reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social__reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social__reports_id_seq OWNED BY public.social__reports.id;


--
-- Name: tenants__pets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants__pets (
    id bigint NOT NULL,
    type character varying(255) NOT NULL,
    breed character varying(255) NOT NULL,
    weight character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: tenants__pets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenants__pets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenants__pets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenants__pets_id_seq OWNED BY public.tenants__pets.id;


--
-- Name: tenants__tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants__tenants (
    id bigint NOT NULL,
    email public.citext,
    first_name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    payment_status character varying(255) DEFAULT 'approved'::character varying NOT NULL,
    residency_status character varying(255) DEFAULT 'current'::character varying NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    uuid uuid NOT NULL,
    phone character varying(255),
    application_id bigint,
    package_pin character varying(255),
    alarm_code character varying(255)
);


--
-- Name: tenants__tenants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenants__tenants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenants__tenants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenants__tenants_id_seq OWNED BY public.tenants__tenants.id;


--
-- Name: tenants__vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants__vehicles (
    id bigint NOT NULL,
    make_model character varying(255) NOT NULL,
    color character varying(255) NOT NULL,
    license_plate character varying(255) NOT NULL,
    state character varying(255) NOT NULL,
    tenant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: tenants__vehicles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tenants__vehicles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tenants__vehicles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tenants__vehicles_id_seq OWNED BY public.tenants__vehicles.id;


--
-- Name: units__default_lease_charges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.units__default_lease_charges (
    id bigint NOT NULL,
    price integer NOT NULL,
    history jsonb DEFAULT '[]'::jsonb,
    default_charge boolean DEFAULT true NOT NULL,
    floor_plan_id bigint,
    account_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: units__default_lease_charges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.units__default_lease_charges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: units__default_lease_charges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.units__default_lease_charges_id_seq OWNED BY public.units__default_lease_charges.id;


--
-- Name: vendor__properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor__properties (
    id bigint NOT NULL,
    vendor_id bigint NOT NULL,
    property_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: vendor__properties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendor__properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendor__properties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendor__properties_id_seq OWNED BY public.vendor__properties.id;


--
-- Name: vendors__categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendors__categories (
    id bigint NOT NULL,
    name character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: vendors__categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendors__categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendors__categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendors__categories_id_seq OWNED BY public.vendors__categories.id;


--
-- Name: vendors__notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendors__notes (
    id bigint NOT NULL,
    text text,
    image character varying(255),
    order_id bigint,
    tenant_id bigint,
    admin_id bigint,
    tech_id bigint,
    vendor_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: vendors__notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendors__notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendors__notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendors__notes_id_seq OWNED BY public.vendors__notes.id;


--
-- Name: vendors__orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendors__orders (
    id bigint NOT NULL,
    status character varying(255) NOT NULL,
    vendor_id bigint,
    category_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    uuid uuid,
    unit_id bigint,
    tenant_id bigint,
    card_item_id bigint,
    priority integer DEFAULT 0 NOT NULL,
    ticket character varying(255) DEFAULT 'UNKNOWN'::character varying NOT NULL,
    creation_date date,
    scheduled date,
    has_pet boolean DEFAULT false NOT NULL,
    entry_allowed boolean DEFAULT false NOT NULL,
    created_by character varying(255),
    admin_id bigint,
    property_id bigint
);


--
-- Name: vendors__orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendors__orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendors__orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendors__orders_id_seq OWNED BY public.vendors__orders.id;


--
-- Name: vendors__skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendors__skills (
    id bigint NOT NULL,
    vendor_id integer,
    category_id integer,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: vendors__skills_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendors__skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendors__skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendors__skills_id_seq OWNED BY public.vendors__skills.id;


--
-- Name: vendors__vendors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendors__vendors (
    id bigint NOT NULL,
    name character varying(255),
    phone character varying(255),
    email public.citext,
    address character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    contact_name character varying(255),
    active boolean DEFAULT true NOT NULL
);


--
-- Name: vendors__vendors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendors__vendors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendors__vendors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendors__vendors_id_seq OWNED BY public.vendors__vendors.id;


--
-- Name: accounting__accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__accounts ALTER COLUMN id SET DEFAULT nextval('public.accounting__charge_types_id_seq'::regclass);


--
-- Name: accounting__bank_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__bank_accounts ALTER COLUMN id SET DEFAULT nextval('public.accounting__bank_accounts_id_seq'::regclass);


--
-- Name: accounting__batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__batches ALTER COLUMN id SET DEFAULT nextval('public.accounting__batches_id_seq'::regclass);


--
-- Name: accounting__budgets__imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__budgets__imports ALTER COLUMN id SET DEFAULT nextval('public.accounting__budgets__imports_id_seq'::regclass);


--
-- Name: accounting__budgets__lines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__budgets__lines ALTER COLUMN id SET DEFAULT nextval('public.accounting__budgets__lines_id_seq'::regclass);


--
-- Name: accounting__categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__categories ALTER COLUMN id SET DEFAULT nextval('public.accounting__categories_id_seq'::regclass);


--
-- Name: accounting__charges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__charges ALTER COLUMN id SET DEFAULT nextval('public.accounting__charges_id_seq'::regclass);


--
-- Name: accounting__checks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__checks ALTER COLUMN id SET DEFAULT nextval('public.accounting__checks_id_seq'::regclass);


--
-- Name: accounting__closings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__closings ALTER COLUMN id SET DEFAULT nextval('public.accounting__closings_id_seq'::regclass);


--
-- Name: accounting__entities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__entities ALTER COLUMN id SET DEFAULT nextval('public.accounting__entities_id_seq'::regclass);


--
-- Name: accounting__invoice_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoice_payments ALTER COLUMN id SET DEFAULT nextval('public.accounting__invoice_payments_id_seq'::regclass);


--
-- Name: accounting__invoices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoices ALTER COLUMN id SET DEFAULT nextval('public.accounting__invoices_id_seq'::regclass);


--
-- Name: accounting__invoicings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoicings ALTER COLUMN id SET DEFAULT nextval('public.accounting__invoicings_id_seq'::regclass);


--
-- Name: accounting__journal_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__journal_entries ALTER COLUMN id SET DEFAULT nextval('public.accounting__journal_entries_id_seq'::regclass);


--
-- Name: accounting__journal_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__journal_pages ALTER COLUMN id SET DEFAULT nextval('public.accounting__journal_pages_id_seq'::regclass);


--
-- Name: accounting__payees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payees ALTER COLUMN id SET DEFAULT nextval('public.accounting__payees_id_seq'::regclass);


--
-- Name: accounting__payment_nsfs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payment_nsfs ALTER COLUMN id SET DEFAULT nextval('public.accounting__payment_nsfs_id_seq'::regclass);


--
-- Name: accounting__payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payments ALTER COLUMN id SET DEFAULT nextval('public.accounting__payments_id_seq'::regclass);


--
-- Name: accounting__receipts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__receipts ALTER COLUMN id SET DEFAULT nextval('public.accounting__receipts_id_seq'::regclass);


--
-- Name: accounting__reconciliation_postings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__reconciliation_postings ALTER COLUMN id SET DEFAULT nextval('public.accounting__reconciliation_postings_id_seq'::regclass);


--
-- Name: accounting__reconciliations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__reconciliations ALTER COLUMN id SET DEFAULT nextval('public.accounting__reconciliations_id_seq'::regclass);


--
-- Name: accounting__registers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__registers ALTER COLUMN id SET DEFAULT nextval('public.accounting__registers_id_seq'::regclass);


--
-- Name: accounting__report_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__report_templates ALTER COLUMN id SET DEFAULT nextval('public.accounting__report_templates_id_seq'::regclass);


--
-- Name: accounting__requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__requests ALTER COLUMN id SET DEFAULT nextval('public.accounting__requests_id_seq'::regclass);


--
-- Name: accounts__accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts__accounts_id_seq'::regclass);


--
-- Name: accounts__autopays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__autopays ALTER COLUMN id SET DEFAULT nextval('public.accounts__autopays_id_seq'::regclass);


--
-- Name: accounts__locks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__locks ALTER COLUMN id SET DEFAULT nextval('public.accounts__locks_id_seq'::regclass);


--
-- Name: accounts__logins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__logins ALTER COLUMN id SET DEFAULT nextval('public.accounts__logins_id_seq'::regclass);


--
-- Name: accounts__payment_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__payment_sources ALTER COLUMN id SET DEFAULT nextval('public.accounts__payment_sources_id_seq'::regclass);


--
-- Name: admins__actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__actions ALTER COLUMN id SET DEFAULT nextval('public.admins__actions_id_seq'::regclass);


--
-- Name: admins__admins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__admins ALTER COLUMN id SET DEFAULT nextval('public.admins__admins_id_seq'::regclass);


--
-- Name: admins__alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__alerts ALTER COLUMN id SET DEFAULT nextval('public.admins__alerts_id_seq'::regclass);


--
-- Name: admins__approval_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approval_attachments ALTER COLUMN id SET DEFAULT nextval('public.admins__approval_attachments_id_seq'::regclass);


--
-- Name: admins__approval_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approval_logs ALTER COLUMN id SET DEFAULT nextval('public.admins__approval_logs_id_seq'::regclass);


--
-- Name: admins__approvals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approvals ALTER COLUMN id SET DEFAULT nextval('public.admins__approvals_id_seq'::regclass);


--
-- Name: admins__approvals_costs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approvals_costs ALTER COLUMN id SET DEFAULT nextval('public.admins__approvals_costs_id_seq'::regclass);


--
-- Name: admins__approvals_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approvals_notes ALTER COLUMN id SET DEFAULT nextval('public.admins__approvals_notes_id_seq'::regclass);


--
-- Name: admins__device_auths id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__device_auths ALTER COLUMN id SET DEFAULT nextval('public.admins__device_auths_id_seq'::regclass);


--
-- Name: admins__devices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__devices ALTER COLUMN id SET DEFAULT nextval('public.admins__devices_id_seq'::regclass);


--
-- Name: admins__entities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__entities ALTER COLUMN id SET DEFAULT nextval('public.admins__entities_id_seq'::regclass);


--
-- Name: admins__messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__messages ALTER COLUMN id SET DEFAULT nextval('public.admins__messages_id_seq'::regclass);


--
-- Name: admins__org_charts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__org_charts ALTER COLUMN id SET DEFAULT nextval('public.admins__org_charts_id_seq'::regclass);


--
-- Name: admins__permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__permissions ALTER COLUMN id SET DEFAULT nextval('public.admins__permissions_id_seq'::regclass);


--
-- Name: admins__profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__profiles ALTER COLUMN id SET DEFAULT nextval('public.admins__profiles_id_seq'::regclass);


--
-- Name: chat__messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__messages ALTER COLUMN id SET DEFAULT nextval('public.chat__messages_id_seq'::regclass);


--
-- Name: chat__read_receipts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__read_receipts ALTER COLUMN id SET DEFAULT nextval('public.chat__read_receipts_id_seq'::regclass);


--
-- Name: chat__room_members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__room_members ALTER COLUMN id SET DEFAULT nextval('public.chat__room_members_id_seq'::regclass);


--
-- Name: chat__rooms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__rooms ALTER COLUMN id SET DEFAULT nextval('public.chat__rooms_id_seq'::regclass);


--
-- Name: data__uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data__uploads ALTER COLUMN id SET DEFAULT nextval('public.data__uploads_id_seq'::regclass);


--
-- Name: exports__categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports__categories ALTER COLUMN id SET DEFAULT nextval('public.exports__categories_id_seq'::regclass);


--
-- Name: exports__documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports__documents ALTER COLUMN id SET DEFAULT nextval('public.exports__documents_id_seq'::regclass);


--
-- Name: exports__recipients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports__recipients ALTER COLUMN id SET DEFAULT nextval('public.exports__recipients_id_seq'::regclass);


--
-- Name: jobs__jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs__jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs__jobs_id_seq'::regclass);


--
-- Name: jobs__migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs__migrations ALTER COLUMN id SET DEFAULT nextval('public.jobs__migrations_id_seq'::regclass);


--
-- Name: leases__custom_packages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__custom_packages ALTER COLUMN id SET DEFAULT nextval('public.leases__custom_packages_id_seq'::regclass);


--
-- Name: leases__forms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__forms ALTER COLUMN id SET DEFAULT nextval('public.leases__forms_id_seq'::regclass);


--
-- Name: leases__leases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__leases ALTER COLUMN id SET DEFAULT nextval('public.leases__leases_id_seq'::regclass);


--
-- Name: leases__renewal_packages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__renewal_packages ALTER COLUMN id SET DEFAULT nextval('public.leases__renewal_packages_id_seq'::regclass);


--
-- Name: leases__renewal_periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__renewal_periods ALTER COLUMN id SET DEFAULT nextval('public.leases__renewal_periods_id_seq'::regclass);


--
-- Name: leases__screenings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__screenings ALTER COLUMN id SET DEFAULT nextval('public.leases__screenings_id_seq'::regclass);


--
-- Name: maintenance__assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__assignments ALTER COLUMN id SET DEFAULT nextval('public.maintenance__assignments_id_seq'::regclass);


--
-- Name: maintenance__card_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__card_items ALTER COLUMN id SET DEFAULT nextval('public.maintenance__card_items_id_seq'::regclass);


--
-- Name: maintenance__cards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__cards ALTER COLUMN id SET DEFAULT nextval('public.maintenance__cards_id_seq'::regclass);


--
-- Name: maintenance__categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__categories ALTER COLUMN id SET DEFAULT nextval('public.maintenance__categories_id_seq'::regclass);


--
-- Name: maintenance__inventory_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__inventory_logs ALTER COLUMN id SET DEFAULT nextval('public.maintenance__inventory_logs_id_seq'::regclass);


--
-- Name: maintenance__jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__jobs ALTER COLUMN id SET DEFAULT nextval('public.maintenance__jobs_id_seq'::regclass);


--
-- Name: maintenance__notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__notes ALTER COLUMN id SET DEFAULT nextval('public.maintenance__notes_id_seq'::regclass);


--
-- Name: maintenance__offers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__offers ALTER COLUMN id SET DEFAULT nextval('public.maintenance__offers_id_seq'::regclass);


--
-- Name: maintenance__open_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__open_history ALTER COLUMN id SET DEFAULT nextval('public.maintenance__open_history_id_seq'::regclass);


--
-- Name: maintenance__orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__orders ALTER COLUMN id SET DEFAULT nextval('public.maintenance__orders_id_seq'::regclass);


--
-- Name: maintenance__paid_time id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__paid_time ALTER COLUMN id SET DEFAULT nextval('public.maintenance__paid_time_id_seq'::regclass);


--
-- Name: maintenance__parts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__parts ALTER COLUMN id SET DEFAULT nextval('public.maintenance__parts_id_seq'::regclass);


--
-- Name: maintenance__presence_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__presence_logs ALTER COLUMN id SET DEFAULT nextval('public.maintenance__presence_logs_id_seq'::regclass);


--
-- Name: maintenance__recurring_orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__recurring_orders ALTER COLUMN id SET DEFAULT nextval('public.maintenance__recurring_orders_id_seq'::regclass);


--
-- Name: maintenance__skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__skills ALTER COLUMN id SET DEFAULT nextval('public.maintenance__skills_id_seq'::regclass);


--
-- Name: maintenance__techs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__techs ALTER COLUMN id SET DEFAULT nextval('public.maintenance__techs_id_seq'::regclass);


--
-- Name: maintenance__timecards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__timecards ALTER COLUMN id SET DEFAULT nextval('public.maintenance__clocks_id_seq'::regclass);


--
-- Name: materials__inventory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__inventory ALTER COLUMN id SET DEFAULT nextval('public.materials__inventory_id_seq'::regclass);


--
-- Name: materials__logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__logs ALTER COLUMN id SET DEFAULT nextval('public.maintenance__material_logs_id_seq'::regclass);


--
-- Name: materials__materials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__materials ALTER COLUMN id SET DEFAULT nextval('public.maintenance__materials_id_seq'::regclass);


--
-- Name: materials__order_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__order_items ALTER COLUMN id SET DEFAULT nextval('public.maintenance__materials_orders_items_id_seq'::regclass);


--
-- Name: materials__orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__orders ALTER COLUMN id SET DEFAULT nextval('public.maintenance__materials_orders_id_seq'::regclass);


--
-- Name: materials__stocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__stocks ALTER COLUMN id SET DEFAULT nextval('public.maintenance__stocks_id_seq'::regclass);


--
-- Name: materials__toolbox_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__toolbox_items ALTER COLUMN id SET DEFAULT nextval('public.materials__toolbox_items_id_seq'::regclass);


--
-- Name: materials__types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__types ALTER COLUMN id SET DEFAULT nextval('public.maintenance__material_types_id_seq'::regclass);


--
-- Name: materials__warehouses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__warehouses ALTER COLUMN id SET DEFAULT nextval('public.materials__warehouses_id_seq'::regclass);


--
-- Name: messaging__emails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__emails ALTER COLUMN id SET DEFAULT nextval('public.messaging__emails_id_seq'::regclass);


--
-- Name: messaging__inboxes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__inboxes ALTER COLUMN id SET DEFAULT nextval('public.messaging__inboxes_id_seq'::regclass);


--
-- Name: messaging__mail_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__mail_addresses ALTER COLUMN id SET DEFAULT nextval('public.messaging__mail_addresses_id_seq'::regclass);


--
-- Name: messaging__mail_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__mail_templates ALTER COLUMN id SET DEFAULT nextval('public.messaging__mail_templates_id_seq'::regclass);


--
-- Name: messaging__mailings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__mailings ALTER COLUMN id SET DEFAULT nextval('public.messaging__mailings_id_seq'::regclass);


--
-- Name: messaging__message_threads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__message_threads ALTER COLUMN id SET DEFAULT nextval('public.messaging__message_threads_id_seq'::regclass);


--
-- Name: messaging__messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__messages ALTER COLUMN id SET DEFAULT nextval('public.messaging__messages_id_seq'::regclass);


--
-- Name: messaging__property_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__property_templates ALTER COLUMN id SET DEFAULT nextval('public.messaging__property_templates_id_seq'::regclass);


--
-- Name: messaging__routes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__routes ALTER COLUMN id SET DEFAULT nextval('public.messaging__routes_id_seq'::regclass);


--
-- Name: properties__admin_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__admin_documents ALTER COLUMN id SET DEFAULT nextval('public.properties__admin_documents_id_seq'::regclass);


--
-- Name: properties__charges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__charges ALTER COLUMN id SET DEFAULT nextval('public.properties__charges_id_seq'::regclass);


--
-- Name: properties__documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__documents ALTER COLUMN id SET DEFAULT nextval('public.properties__documents_id_seq'::regclass);


--
-- Name: properties__evictions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__evictions ALTER COLUMN id SET DEFAULT nextval('public.properties__evictions_id_seq'::regclass);


--
-- Name: properties__features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__features ALTER COLUMN id SET DEFAULT nextval('public.properties__features_id_seq'::regclass);


--
-- Name: properties__floor_plan_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__floor_plan_features ALTER COLUMN id SET DEFAULT nextval('public.properties__floor_plan_features_id_seq'::regclass);


--
-- Name: properties__floor_plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__floor_plans ALTER COLUMN id SET DEFAULT nextval('public.properties__floor_plans_id_seq'::regclass);


--
-- Name: properties__insurances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__insurances ALTER COLUMN id SET DEFAULT nextval('public.properties__insurances_id_seq'::regclass);


--
-- Name: properties__letter_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__letter_templates ALTER COLUMN id SET DEFAULT nextval('public.properties__letter_templates_id_seq'::regclass);


--
-- Name: properties__occupancies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__occupancies ALTER COLUMN id SET DEFAULT nextval('public.properties__occupancies_id_seq'::regclass);


--
-- Name: properties__occupants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__occupants ALTER COLUMN id SET DEFAULT nextval('public.properties__occupants_id_seq'::regclass);


--
-- Name: properties__packages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__packages ALTER COLUMN id SET DEFAULT nextval('public.properties__packages_id_seq'::regclass);


--
-- Name: properties__phone__lines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__phone__lines ALTER COLUMN id SET DEFAULT nextval('public.properties__phone__lines_id_seq'::regclass);


--
-- Name: properties__processors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__processors ALTER COLUMN id SET DEFAULT nextval('public.properties__processors_id_seq'::regclass);


--
-- Name: properties__properties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__properties ALTER COLUMN id SET DEFAULT nextval('public.properties__properties_id_seq'::regclass);


--
-- Name: properties__property_admin_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__property_admin_documents ALTER COLUMN id SET DEFAULT nextval('public.properties__property_admin_documents_id_seq'::regclass);


--
-- Name: properties__recurring_letters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__recurring_letters ALTER COLUMN id SET DEFAULT nextval('public.properties__recurring_letters_id_seq'::regclass);


--
-- Name: properties__regions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__regions ALTER COLUMN id SET DEFAULT nextval('public.properties__regions_id_seq'::regclass);


--
-- Name: properties__resident_event_attendances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__resident_event_attendances ALTER COLUMN id SET DEFAULT nextval('public.properties__resident_event_attendances_id_seq'::regclass);


--
-- Name: properties__resident_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__resident_events ALTER COLUMN id SET DEFAULT nextval('public.properties__resident_events_id_seq'::regclass);


--
-- Name: properties__scopings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__scopings ALTER COLUMN id SET DEFAULT nextval('public.properties__scopings_id_seq'::regclass);


--
-- Name: properties__settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__settings ALTER COLUMN id SET DEFAULT nextval('public.properties__settings_id_seq'::regclass);


--
-- Name: properties__unit_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__unit_features ALTER COLUMN id SET DEFAULT nextval('public.properties__unit_features_id_seq'::regclass);


--
-- Name: properties__units id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__units ALTER COLUMN id SET DEFAULT nextval('public.properties__units_id_seq'::regclass);


--
-- Name: properties__visits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__visits ALTER COLUMN id SET DEFAULT nextval('public.properties__visits_id_seq'::regclass);


--
-- Name: prospects__closures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__closures ALTER COLUMN id SET DEFAULT nextval('public.prospects__closures_id_seq'::regclass);


--
-- Name: prospects__memos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__memos ALTER COLUMN id SET DEFAULT nextval('public.prospects__memos_id_seq'::regclass);


--
-- Name: prospects__openings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__openings ALTER COLUMN id SET DEFAULT nextval('public.prospects__openings_id_seq'::regclass);


--
-- Name: prospects__prospects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__prospects ALTER COLUMN id SET DEFAULT nextval('public.prospects__prospects_id_seq'::regclass);


--
-- Name: prospects__referral id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__referral ALTER COLUMN id SET DEFAULT nextval('public.prospects__referral_id_seq'::regclass);


--
-- Name: prospects__showings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__showings ALTER COLUMN id SET DEFAULT nextval('public.prospects__showings_id_seq'::regclass);


--
-- Name: prospects__traffic_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__traffic_sources ALTER COLUMN id SET DEFAULT nextval('public.prospects__traffic_sources_id_seq'::regclass);


--
-- Name: rent_apply__documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__documents ALTER COLUMN id SET DEFAULT nextval('public.rent_apply__documents_id_seq'::regclass);


--
-- Name: rent_apply__emergency_contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__emergency_contacts ALTER COLUMN id SET DEFAULT nextval('public.rent_apply__emergency_contacts_id_seq'::regclass);


--
-- Name: rent_apply__employments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__employments ALTER COLUMN id SET DEFAULT nextval('public.rent_apply__employments_id_seq'::regclass);


--
-- Name: rent_apply__histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__histories ALTER COLUMN id SET DEFAULT nextval('public.rent_apply__histories_id_seq'::regclass);


--
-- Name: rent_apply__incomes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__incomes ALTER COLUMN id SET DEFAULT nextval('public.rent_apply__incomes_id_seq'::regclass);


--
-- Name: rent_apply__memos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__memos ALTER COLUMN id SET DEFAULT nextval('public.rent_apply__memos_id_seq'::regclass);


--
-- Name: rent_apply__move_ins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__move_ins ALTER COLUMN id SET DEFAULT nextval('public.rent_apply__move_ins_id_seq'::regclass);


--
-- Name: rent_apply__persons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__persons ALTER COLUMN id SET DEFAULT nextval('public.rent_apply__persons_id_seq'::regclass);


--
-- Name: rent_apply__pets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__pets ALTER COLUMN id SET DEFAULT nextval('public.rent_apply__pets_id_seq'::regclass);


--
-- Name: rent_apply__rent_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__rent_applications ALTER COLUMN id SET DEFAULT nextval('public.rent_apply__rent_applications_id_seq'::regclass);


--
-- Name: rent_apply__saved_forms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__saved_forms ALTER COLUMN id SET DEFAULT nextval('public.rent_apply__saved_forms_id_seq'::regclass);


--
-- Name: rent_apply__vehicles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__vehicles ALTER COLUMN id SET DEFAULT nextval('public.rent_apply__vehicles_id_seq'::regclass);


--
-- Name: rewards__awards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__awards ALTER COLUMN id SET DEFAULT nextval('public.accounts__rewards_id_seq'::regclass);


--
-- Name: rewards__prizes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__prizes ALTER COLUMN id SET DEFAULT nextval('public.accounts__prizes_id_seq'::regclass);


--
-- Name: rewards__purchases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__purchases ALTER COLUMN id SET DEFAULT nextval('public.accounts__purchases_id_seq'::regclass);


--
-- Name: rewards__types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__types ALTER COLUMN id SET DEFAULT nextval('public.accounts__reward_types_id_seq'::regclass);


--
-- Name: settings__banks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings__banks ALTER COLUMN id SET DEFAULT nextval('public.accounts__banks_id_seq'::regclass);


--
-- Name: settings__damages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings__damages ALTER COLUMN id SET DEFAULT nextval('public.settings__damages_id_seq'::regclass);


--
-- Name: settings__move_out_reasons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings__move_out_reasons ALTER COLUMN id SET DEFAULT nextval('public.settings__move_out_reasons_id_seq'::regclass);


--
-- Name: social__blocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__blocks ALTER COLUMN id SET DEFAULT nextval('public.social__blocks_id_seq'::regclass);


--
-- Name: social__posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__posts ALTER COLUMN id SET DEFAULT nextval('public.social__posts_id_seq'::regclass);


--
-- Name: social__posts_likes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__posts_likes ALTER COLUMN id SET DEFAULT nextval('public.social__posts_likes_id_seq'::regclass);


--
-- Name: social__reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__reports ALTER COLUMN id SET DEFAULT nextval('public.social__reports_id_seq'::regclass);


--
-- Name: tenants__pets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants__pets ALTER COLUMN id SET DEFAULT nextval('public.tenants__pets_id_seq'::regclass);


--
-- Name: tenants__tenants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants__tenants ALTER COLUMN id SET DEFAULT nextval('public.tenants__tenants_id_seq'::regclass);


--
-- Name: tenants__vehicles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants__vehicles ALTER COLUMN id SET DEFAULT nextval('public.tenants__vehicles_id_seq'::regclass);


--
-- Name: units__default_lease_charges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units__default_lease_charges ALTER COLUMN id SET DEFAULT nextval('public.units__default_lease_charges_id_seq'::regclass);


--
-- Name: vendor__properties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor__properties ALTER COLUMN id SET DEFAULT nextval('public.vendor__properties_id_seq'::regclass);


--
-- Name: vendors__categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__categories ALTER COLUMN id SET DEFAULT nextval('public.vendors__categories_id_seq'::regclass);


--
-- Name: vendors__notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__notes ALTER COLUMN id SET DEFAULT nextval('public.vendors__notes_id_seq'::regclass);


--
-- Name: vendors__orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__orders ALTER COLUMN id SET DEFAULT nextval('public.vendors__orders_id_seq'::regclass);


--
-- Name: vendors__skills id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__skills ALTER COLUMN id SET DEFAULT nextval('public.vendors__skills_id_seq'::regclass);


--
-- Name: vendors__vendors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__vendors ALTER COLUMN id SET DEFAULT nextval('public.vendors__vendors_id_seq'::regclass);


--
-- Name: accounting__bank_accounts accounting__bank_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__bank_accounts
    ADD CONSTRAINT accounting__bank_accounts_pkey PRIMARY KEY (id);


--
-- Name: accounting__batches accounting__batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__batches
    ADD CONSTRAINT accounting__batches_pkey PRIMARY KEY (id);


--
-- Name: accounting__budgets__imports accounting__budgets__imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__budgets__imports
    ADD CONSTRAINT accounting__budgets__imports_pkey PRIMARY KEY (id);


--
-- Name: accounting__budgets__lines accounting__budgets__lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__budgets__lines
    ADD CONSTRAINT accounting__budgets__lines_pkey PRIMARY KEY (id);


--
-- Name: accounting__categories accounting__categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__categories
    ADD CONSTRAINT accounting__categories_pkey PRIMARY KEY (id);


--
-- Name: accounting__accounts accounting__charge_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__accounts
    ADD CONSTRAINT accounting__charge_types_pkey PRIMARY KEY (id);


--
-- Name: accounting__charges accounting__charges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__charges
    ADD CONSTRAINT accounting__charges_pkey PRIMARY KEY (id);


--
-- Name: accounting__checks accounting__checks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__checks
    ADD CONSTRAINT accounting__checks_pkey PRIMARY KEY (id);


--
-- Name: accounting__closings accounting__closings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__closings
    ADD CONSTRAINT accounting__closings_pkey PRIMARY KEY (id);


--
-- Name: accounting__entities accounting__entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__entities
    ADD CONSTRAINT accounting__entities_pkey PRIMARY KEY (id);


--
-- Name: accounting__invoice_payments accounting__invoice_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoice_payments
    ADD CONSTRAINT accounting__invoice_payments_pkey PRIMARY KEY (id);


--
-- Name: accounting__invoices accounting__invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoices
    ADD CONSTRAINT accounting__invoices_pkey PRIMARY KEY (id);


--
-- Name: accounting__invoicings accounting__invoicings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoicings
    ADD CONSTRAINT accounting__invoicings_pkey PRIMARY KEY (id);


--
-- Name: accounting__journal_entries accounting__journal_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__journal_entries
    ADD CONSTRAINT accounting__journal_entries_pkey PRIMARY KEY (id);


--
-- Name: accounting__journal_pages accounting__journal_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__journal_pages
    ADD CONSTRAINT accounting__journal_pages_pkey PRIMARY KEY (id);


--
-- Name: accounting__payees accounting__payees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payees
    ADD CONSTRAINT accounting__payees_pkey PRIMARY KEY (id);


--
-- Name: accounting__payment_nsfs accounting__payment_nsfs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payment_nsfs
    ADD CONSTRAINT accounting__payment_nsfs_pkey PRIMARY KEY (id);


--
-- Name: accounting__payments accounting__payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payments
    ADD CONSTRAINT accounting__payments_pkey PRIMARY KEY (id);


--
-- Name: accounting__receipts accounting__receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__receipts
    ADD CONSTRAINT accounting__receipts_pkey PRIMARY KEY (id);


--
-- Name: accounting__reconciliation_postings accounting__reconciliation_postings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__reconciliation_postings
    ADD CONSTRAINT accounting__reconciliation_postings_pkey PRIMARY KEY (id);


--
-- Name: accounting__reconciliations accounting__reconciliations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__reconciliations
    ADD CONSTRAINT accounting__reconciliations_pkey PRIMARY KEY (id);


--
-- Name: accounting__registers accounting__registers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__registers
    ADD CONSTRAINT accounting__registers_pkey PRIMARY KEY (id);


--
-- Name: accounting__report_templates accounting__report_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__report_templates
    ADD CONSTRAINT accounting__report_templates_pkey PRIMARY KEY (id);


--
-- Name: accounting__requests accounting__requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__requests
    ADD CONSTRAINT accounting__requests_pkey PRIMARY KEY (id);


--
-- Name: accounts__accounts accounts__accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__accounts
    ADD CONSTRAINT accounts__accounts_pkey PRIMARY KEY (id);


--
-- Name: accounts__autopays accounts__autopays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__autopays
    ADD CONSTRAINT accounts__autopays_pkey PRIMARY KEY (id);


--
-- Name: settings__banks accounts__banks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings__banks
    ADD CONSTRAINT accounts__banks_pkey PRIMARY KEY (id);


--
-- Name: accounts__locks accounts__locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__locks
    ADD CONSTRAINT accounts__locks_pkey PRIMARY KEY (id);


--
-- Name: accounts__logins accounts__logins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__logins
    ADD CONSTRAINT accounts__logins_pkey PRIMARY KEY (id);


--
-- Name: accounts__payment_sources accounts__payment_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__payment_sources
    ADD CONSTRAINT accounts__payment_sources_pkey PRIMARY KEY (id);


--
-- Name: rewards__prizes accounts__prizes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__prizes
    ADD CONSTRAINT accounts__prizes_pkey PRIMARY KEY (id);


--
-- Name: rewards__purchases accounts__purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__purchases
    ADD CONSTRAINT accounts__purchases_pkey PRIMARY KEY (id);


--
-- Name: rewards__types accounts__reward_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__types
    ADD CONSTRAINT accounts__reward_types_pkey PRIMARY KEY (id);


--
-- Name: rewards__awards accounts__rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__awards
    ADD CONSTRAINT accounts__rewards_pkey PRIMARY KEY (id);


--
-- Name: admins__actions admins__actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__actions
    ADD CONSTRAINT admins__actions_pkey PRIMARY KEY (id);


--
-- Name: admins__admins admins__admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__admins
    ADD CONSTRAINT admins__admins_pkey PRIMARY KEY (id);


--
-- Name: admins__alerts admins__alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__alerts
    ADD CONSTRAINT admins__alerts_pkey PRIMARY KEY (id);


--
-- Name: admins__approval_attachments admins__approval_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approval_attachments
    ADD CONSTRAINT admins__approval_attachments_pkey PRIMARY KEY (id);


--
-- Name: admins__approval_logs admins__approval_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approval_logs
    ADD CONSTRAINT admins__approval_logs_pkey PRIMARY KEY (id);


--
-- Name: admins__approvals_costs admins__approvals_costs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approvals_costs
    ADD CONSTRAINT admins__approvals_costs_pkey PRIMARY KEY (id);


--
-- Name: admins__approvals_notes admins__approvals_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approvals_notes
    ADD CONSTRAINT admins__approvals_notes_pkey PRIMARY KEY (id);


--
-- Name: admins__approvals admins__approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approvals
    ADD CONSTRAINT admins__approvals_pkey PRIMARY KEY (id);


--
-- Name: admins__device_auths admins__device_auths_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__device_auths
    ADD CONSTRAINT admins__device_auths_pkey PRIMARY KEY (id);


--
-- Name: admins__devices admins__devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__devices
    ADD CONSTRAINT admins__devices_pkey PRIMARY KEY (id);


--
-- Name: admins__entities admins__entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__entities
    ADD CONSTRAINT admins__entities_pkey PRIMARY KEY (id);


--
-- Name: admins__messages admins__messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__messages
    ADD CONSTRAINT admins__messages_pkey PRIMARY KEY (id);


--
-- Name: admins__org_charts admins__org_charts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__org_charts
    ADD CONSTRAINT admins__org_charts_pkey PRIMARY KEY (id);


--
-- Name: admins__permissions admins__permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__permissions
    ADD CONSTRAINT admins__permissions_pkey PRIMARY KEY (id);


--
-- Name: admins__profiles admins__profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__profiles
    ADD CONSTRAINT admins__profiles_pkey PRIMARY KEY (id);


--
-- Name: chat__messages chat__messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__messages
    ADD CONSTRAINT chat__messages_pkey PRIMARY KEY (id);


--
-- Name: chat__read_receipts chat__read_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__read_receipts
    ADD CONSTRAINT chat__read_receipts_pkey PRIMARY KEY (id);


--
-- Name: chat__room_members chat__room_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__room_members
    ADD CONSTRAINT chat__room_members_pkey PRIMARY KEY (id);


--
-- Name: chat__rooms chat__rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__rooms
    ADD CONSTRAINT chat__rooms_pkey PRIMARY KEY (id);


--
-- Name: data__uploads data__uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data__uploads
    ADD CONSTRAINT data__uploads_pkey PRIMARY KEY (id);


--
-- Name: leases__leases duration_overlap; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__leases
    ADD CONSTRAINT duration_overlap EXCLUDE USING gist (unit_id WITH =, daterange(start_date,
CASE
    WHEN (move_out_date IS NULL) THEN end_date
    ELSE move_out_date
END) WITH &&);


--
-- Name: exports__categories exports__categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports__categories
    ADD CONSTRAINT exports__categories_pkey PRIMARY KEY (id);


--
-- Name: exports__documents exports__documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports__documents
    ADD CONSTRAINT exports__documents_pkey PRIMARY KEY (id);


--
-- Name: exports__recipients exports__recipients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports__recipients
    ADD CONSTRAINT exports__recipients_pkey PRIMARY KEY (id);


--
-- Name: jobs__jobs jobs__jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs__jobs
    ADD CONSTRAINT jobs__jobs_pkey PRIMARY KEY (id);


--
-- Name: jobs__migrations jobs__migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs__migrations
    ADD CONSTRAINT jobs__migrations_pkey PRIMARY KEY (id);


--
-- Name: leases__custom_packages leases__custom_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__custom_packages
    ADD CONSTRAINT leases__custom_packages_pkey PRIMARY KEY (id);


--
-- Name: leases__forms leases__forms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__forms
    ADD CONSTRAINT leases__forms_pkey PRIMARY KEY (id);


--
-- Name: leases__leases leases__leases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__leases
    ADD CONSTRAINT leases__leases_pkey PRIMARY KEY (id);


--
-- Name: leases__renewal_packages leases__renewal_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__renewal_packages
    ADD CONSTRAINT leases__renewal_packages_pkey PRIMARY KEY (id);


--
-- Name: leases__renewal_periods leases__renewal_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__renewal_periods
    ADD CONSTRAINT leases__renewal_periods_pkey PRIMARY KEY (id);


--
-- Name: leases__screenings leases__screenings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__screenings
    ADD CONSTRAINT leases__screenings_pkey PRIMARY KEY (id);


--
-- Name: maintenance__assignments maintenance__assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__assignments
    ADD CONSTRAINT maintenance__assignments_pkey PRIMARY KEY (id);


--
-- Name: maintenance__card_items maintenance__card_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__card_items
    ADD CONSTRAINT maintenance__card_items_pkey PRIMARY KEY (id);


--
-- Name: maintenance__cards maintenance__cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__cards
    ADD CONSTRAINT maintenance__cards_pkey PRIMARY KEY (id);


--
-- Name: maintenance__categories maintenance__categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__categories
    ADD CONSTRAINT maintenance__categories_pkey PRIMARY KEY (id);


--
-- Name: maintenance__timecards maintenance__clocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__timecards
    ADD CONSTRAINT maintenance__clocks_pkey PRIMARY KEY (id);


--
-- Name: maintenance__inventory_logs maintenance__inventory_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__inventory_logs
    ADD CONSTRAINT maintenance__inventory_logs_pkey PRIMARY KEY (id);


--
-- Name: maintenance__jobs maintenance__jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__jobs
    ADD CONSTRAINT maintenance__jobs_pkey PRIMARY KEY (id);


--
-- Name: materials__logs maintenance__material_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__logs
    ADD CONSTRAINT maintenance__material_logs_pkey PRIMARY KEY (id);


--
-- Name: materials__types maintenance__material_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__types
    ADD CONSTRAINT maintenance__material_types_pkey PRIMARY KEY (id);


--
-- Name: materials__order_items maintenance__materials_orders_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__order_items
    ADD CONSTRAINT maintenance__materials_orders_items_pkey PRIMARY KEY (id);


--
-- Name: materials__orders maintenance__materials_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__orders
    ADD CONSTRAINT maintenance__materials_orders_pkey PRIMARY KEY (id);


--
-- Name: materials__materials maintenance__materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__materials
    ADD CONSTRAINT maintenance__materials_pkey PRIMARY KEY (id);


--
-- Name: maintenance__notes maintenance__notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__notes
    ADD CONSTRAINT maintenance__notes_pkey PRIMARY KEY (id);


--
-- Name: maintenance__offers maintenance__offers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__offers
    ADD CONSTRAINT maintenance__offers_pkey PRIMARY KEY (id);


--
-- Name: maintenance__open_history maintenance__open_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__open_history
    ADD CONSTRAINT maintenance__open_history_pkey PRIMARY KEY (id);


--
-- Name: maintenance__orders maintenance__orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__orders
    ADD CONSTRAINT maintenance__orders_pkey PRIMARY KEY (id);


--
-- Name: maintenance__paid_time maintenance__paid_time_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__paid_time
    ADD CONSTRAINT maintenance__paid_time_pkey PRIMARY KEY (id);


--
-- Name: maintenance__parts maintenance__parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__parts
    ADD CONSTRAINT maintenance__parts_pkey PRIMARY KEY (id);


--
-- Name: maintenance__presence_logs maintenance__presence_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__presence_logs
    ADD CONSTRAINT maintenance__presence_logs_pkey PRIMARY KEY (id);


--
-- Name: maintenance__recurring_orders maintenance__recurring_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__recurring_orders
    ADD CONSTRAINT maintenance__recurring_orders_pkey PRIMARY KEY (id);


--
-- Name: maintenance__skills maintenance__skills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__skills
    ADD CONSTRAINT maintenance__skills_pkey PRIMARY KEY (id);


--
-- Name: materials__stocks maintenance__stocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__stocks
    ADD CONSTRAINT maintenance__stocks_pkey PRIMARY KEY (id);


--
-- Name: maintenance__techs maintenance__techs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__techs
    ADD CONSTRAINT maintenance__techs_pkey PRIMARY KEY (id);


--
-- Name: materials__inventory materials__inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__inventory
    ADD CONSTRAINT materials__inventory_pkey PRIMARY KEY (id);


--
-- Name: materials__toolbox_items materials__toolbox_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__toolbox_items
    ADD CONSTRAINT materials__toolbox_items_pkey PRIMARY KEY (id);


--
-- Name: materials__warehouses materials__warehouses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__warehouses
    ADD CONSTRAINT materials__warehouses_pkey PRIMARY KEY (id);


--
-- Name: messaging__emails messaging__emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__emails
    ADD CONSTRAINT messaging__emails_pkey PRIMARY KEY (id);


--
-- Name: messaging__inboxes messaging__inboxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__inboxes
    ADD CONSTRAINT messaging__inboxes_pkey PRIMARY KEY (id);


--
-- Name: messaging__mail_addresses messaging__mail_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__mail_addresses
    ADD CONSTRAINT messaging__mail_addresses_pkey PRIMARY KEY (id);


--
-- Name: messaging__mail_templates messaging__mail_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__mail_templates
    ADD CONSTRAINT messaging__mail_templates_pkey PRIMARY KEY (id);


--
-- Name: messaging__mailings messaging__mailings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__mailings
    ADD CONSTRAINT messaging__mailings_pkey PRIMARY KEY (id);


--
-- Name: messaging__message_threads messaging__message_threads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__message_threads
    ADD CONSTRAINT messaging__message_threads_pkey PRIMARY KEY (id);


--
-- Name: messaging__messages messaging__messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__messages
    ADD CONSTRAINT messaging__messages_pkey PRIMARY KEY (id);


--
-- Name: messaging__property_templates messaging__property_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__property_templates
    ADD CONSTRAINT messaging__property_templates_pkey PRIMARY KEY (id);


--
-- Name: messaging__routes messaging__routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__routes
    ADD CONSTRAINT messaging__routes_pkey PRIMARY KEY (id);


--
-- Name: leases__renewal_packages min_max_overlap; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__renewal_packages
    ADD CONSTRAINT min_max_overlap EXCLUDE USING gist (renewal_period_id WITH =, int4range(min, max) WITH &&);


--
-- Name: leases__renewal_periods period_overlap; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__renewal_periods
    ADD CONSTRAINT period_overlap EXCLUDE USING gist (property_id WITH =, daterange(start_date, end_date) WITH &&);


--
-- Name: properties__admin_documents properties__admin_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__admin_documents
    ADD CONSTRAINT properties__admin_documents_pkey PRIMARY KEY (id);


--
-- Name: properties__charges properties__charges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__charges
    ADD CONSTRAINT properties__charges_pkey PRIMARY KEY (id);


--
-- Name: properties__documents properties__documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__documents
    ADD CONSTRAINT properties__documents_pkey PRIMARY KEY (id);


--
-- Name: properties__evictions properties__evictions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__evictions
    ADD CONSTRAINT properties__evictions_pkey PRIMARY KEY (id);


--
-- Name: properties__features properties__features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__features
    ADD CONSTRAINT properties__features_pkey PRIMARY KEY (id);


--
-- Name: properties__floor_plan_features properties__floor_plan_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__floor_plan_features
    ADD CONSTRAINT properties__floor_plan_features_pkey PRIMARY KEY (id);


--
-- Name: properties__floor_plans properties__floor_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__floor_plans
    ADD CONSTRAINT properties__floor_plans_pkey PRIMARY KEY (id);


--
-- Name: properties__insurances properties__insurances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__insurances
    ADD CONSTRAINT properties__insurances_pkey PRIMARY KEY (id);


--
-- Name: properties__letter_templates properties__letter_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__letter_templates
    ADD CONSTRAINT properties__letter_templates_pkey PRIMARY KEY (id);


--
-- Name: properties__occupancies properties__occupancies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__occupancies
    ADD CONSTRAINT properties__occupancies_pkey PRIMARY KEY (id);


--
-- Name: properties__occupants properties__occupants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__occupants
    ADD CONSTRAINT properties__occupants_pkey PRIMARY KEY (id);


--
-- Name: properties__packages properties__packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__packages
    ADD CONSTRAINT properties__packages_pkey PRIMARY KEY (id);


--
-- Name: properties__phone__lines properties__phone__lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__phone__lines
    ADD CONSTRAINT properties__phone__lines_pkey PRIMARY KEY (id);


--
-- Name: properties__processors properties__processors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__processors
    ADD CONSTRAINT properties__processors_pkey PRIMARY KEY (id);


--
-- Name: properties__properties properties__properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__properties
    ADD CONSTRAINT properties__properties_pkey PRIMARY KEY (id);


--
-- Name: properties__property_admin_documents properties__property_admin_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__property_admin_documents
    ADD CONSTRAINT properties__property_admin_documents_pkey PRIMARY KEY (id);


--
-- Name: properties__recurring_letters properties__recurring_letters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__recurring_letters
    ADD CONSTRAINT properties__recurring_letters_pkey PRIMARY KEY (id);


--
-- Name: properties__regions properties__regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__regions
    ADD CONSTRAINT properties__regions_pkey PRIMARY KEY (id);


--
-- Name: properties__resident_event_attendances properties__resident_event_attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__resident_event_attendances
    ADD CONSTRAINT properties__resident_event_attendances_pkey PRIMARY KEY (id);


--
-- Name: properties__resident_events properties__resident_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__resident_events
    ADD CONSTRAINT properties__resident_events_pkey PRIMARY KEY (id);


--
-- Name: properties__scopings properties__scopings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__scopings
    ADD CONSTRAINT properties__scopings_pkey PRIMARY KEY (id);


--
-- Name: properties__settings properties__settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__settings
    ADD CONSTRAINT properties__settings_pkey PRIMARY KEY (id);


--
-- Name: properties__unit_features properties__unit_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__unit_features
    ADD CONSTRAINT properties__unit_features_pkey PRIMARY KEY (id);


--
-- Name: properties__units properties__units_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__units
    ADD CONSTRAINT properties__units_pkey PRIMARY KEY (id);


--
-- Name: properties__visits properties__visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__visits
    ADD CONSTRAINT properties__visits_pkey PRIMARY KEY (id);


--
-- Name: prospects__closures prospects__closures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__closures
    ADD CONSTRAINT prospects__closures_pkey PRIMARY KEY (id);


--
-- Name: prospects__memos prospects__memos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__memos
    ADD CONSTRAINT prospects__memos_pkey PRIMARY KEY (id);


--
-- Name: prospects__openings prospects__openings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__openings
    ADD CONSTRAINT prospects__openings_pkey PRIMARY KEY (id);


--
-- Name: prospects__prospects prospects__prospects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__prospects
    ADD CONSTRAINT prospects__prospects_pkey PRIMARY KEY (id);


--
-- Name: prospects__referral prospects__referral_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__referral
    ADD CONSTRAINT prospects__referral_pkey PRIMARY KEY (id);


--
-- Name: prospects__showings prospects__showings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__showings
    ADD CONSTRAINT prospects__showings_pkey PRIMARY KEY (id);


--
-- Name: prospects__traffic_sources prospects__traffic_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__traffic_sources
    ADD CONSTRAINT prospects__traffic_sources_pkey PRIMARY KEY (id);


--
-- Name: rent_apply__documents rent_apply__documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__documents
    ADD CONSTRAINT rent_apply__documents_pkey PRIMARY KEY (id);


--
-- Name: rent_apply__emergency_contacts rent_apply__emergency_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__emergency_contacts
    ADD CONSTRAINT rent_apply__emergency_contacts_pkey PRIMARY KEY (id);


--
-- Name: rent_apply__employments rent_apply__employments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__employments
    ADD CONSTRAINT rent_apply__employments_pkey PRIMARY KEY (id);


--
-- Name: rent_apply__histories rent_apply__histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__histories
    ADD CONSTRAINT rent_apply__histories_pkey PRIMARY KEY (id);


--
-- Name: rent_apply__incomes rent_apply__incomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__incomes
    ADD CONSTRAINT rent_apply__incomes_pkey PRIMARY KEY (id);


--
-- Name: rent_apply__memos rent_apply__memos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__memos
    ADD CONSTRAINT rent_apply__memos_pkey PRIMARY KEY (id);


--
-- Name: rent_apply__move_ins rent_apply__move_ins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__move_ins
    ADD CONSTRAINT rent_apply__move_ins_pkey PRIMARY KEY (id);


--
-- Name: rent_apply__persons rent_apply__persons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__persons
    ADD CONSTRAINT rent_apply__persons_pkey PRIMARY KEY (id);


--
-- Name: rent_apply__pets rent_apply__pets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__pets
    ADD CONSTRAINT rent_apply__pets_pkey PRIMARY KEY (id);


--
-- Name: rent_apply__rent_applications rent_apply__rent_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__rent_applications
    ADD CONSTRAINT rent_apply__rent_applications_pkey PRIMARY KEY (id);


--
-- Name: rent_apply__saved_forms rent_apply__saved_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__saved_forms
    ADD CONSTRAINT rent_apply__saved_forms_pkey PRIMARY KEY (id);


--
-- Name: rent_apply__vehicles rent_apply__vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__vehicles
    ADD CONSTRAINT rent_apply__vehicles_pkey PRIMARY KEY (id);


--
-- Name: accounting__reconciliation_postings reocniliation_overlap; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__reconciliation_postings
    ADD CONSTRAINT reocniliation_overlap EXCLUDE USING gist (bank_account_id WITH =, daterange(start_date, end_date) WITH &&);


--
-- Name: prospects__showings scheduling_conflict; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__showings
    ADD CONSTRAINT scheduling_conflict EXCLUDE USING gist (date WITH =, prospect_id WITH =, int4range(start_time, end_time) WITH &&);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: settings__damages settings__damages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings__damages
    ADD CONSTRAINT settings__damages_pkey PRIMARY KEY (id);


--
-- Name: settings__move_out_reasons settings__move_out_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings__move_out_reasons
    ADD CONSTRAINT settings__move_out_reasons_pkey PRIMARY KEY (id);


--
-- Name: social__blocks social__blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__blocks
    ADD CONSTRAINT social__blocks_pkey PRIMARY KEY (id);


--
-- Name: social__posts_likes social__posts_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__posts_likes
    ADD CONSTRAINT social__posts_likes_pkey PRIMARY KEY (id);


--
-- Name: social__posts social__posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__posts
    ADD CONSTRAINT social__posts_pkey PRIMARY KEY (id);


--
-- Name: social__reports social__reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__reports
    ADD CONSTRAINT social__reports_pkey PRIMARY KEY (id);


--
-- Name: tenants__pets tenants__pets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants__pets
    ADD CONSTRAINT tenants__pets_pkey PRIMARY KEY (id);


--
-- Name: tenants__tenants tenants__tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants__tenants
    ADD CONSTRAINT tenants__tenants_pkey PRIMARY KEY (id);


--
-- Name: tenants__vehicles tenants__vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants__vehicles
    ADD CONSTRAINT tenants__vehicles_pkey PRIMARY KEY (id);


--
-- Name: units__default_lease_charges units__default_lease_charges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units__default_lease_charges
    ADD CONSTRAINT units__default_lease_charges_pkey PRIMARY KEY (id);


--
-- Name: vendor__properties vendor__properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor__properties
    ADD CONSTRAINT vendor__properties_pkey PRIMARY KEY (id);


--
-- Name: vendors__categories vendors__categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__categories
    ADD CONSTRAINT vendors__categories_pkey PRIMARY KEY (id);


--
-- Name: vendors__notes vendors__notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__notes
    ADD CONSTRAINT vendors__notes_pkey PRIMARY KEY (id);


--
-- Name: vendors__orders vendors__orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__orders
    ADD CONSTRAINT vendors__orders_pkey PRIMARY KEY (id);


--
-- Name: vendors__skills vendors__skills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__skills
    ADD CONSTRAINT vendors__skills_pkey PRIMARY KEY (id);


--
-- Name: vendors__vendors vendors__vendors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__vendors
    ADD CONSTRAINT vendors__vendors_pkey PRIMARY KEY (id);


--
-- Name: accounting__accounts_charge_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__accounts_charge_code_index ON public.accounting__accounts USING btree (charge_code);


--
-- Name: accounting__accounts_name_num_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__accounts_name_num_index ON public.accounting__accounts USING btree (name, num);


--
-- Name: accounting__accounts_num_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__accounts_num_index ON public.accounting__accounts USING btree (num);


--
-- Name: accounting__accounts_source_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__accounts_source_id_index ON public.accounting__accounts USING btree (source_id);


--
-- Name: accounting__bank_accounts_cash_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__bank_accounts_cash_account_id_index ON public.accounting__bank_accounts USING btree (account_id);


--
-- Name: accounting__batches_bank_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__batches_bank_account_id_index ON public.accounting__batches USING btree (bank_account_id);


--
-- Name: accounting__batches_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__batches_property_id_index ON public.accounting__batches USING btree (property_id);


--
-- Name: accounting__budgets__imports_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__budgets__imports_admin_id_index ON public.accounting__budgets__imports USING btree (admin_id);


--
-- Name: accounting__budgets__imports_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__budgets__imports_property_id_index ON public.accounting__budgets__imports USING btree (property_id);


--
-- Name: accounting__budgets__lines_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__budgets__lines_account_id_index ON public.accounting__budgets__lines USING btree (account_id);


--
-- Name: accounting__budgets__lines_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__budgets__lines_admin_id_index ON public.accounting__budgets__lines USING btree (admin_id);


--
-- Name: accounting__budgets__lines_import_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__budgets__lines_import_id_index ON public.accounting__budgets__lines USING btree (import_id);


--
-- Name: accounting__budgets__lines_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__budgets__lines_property_id_index ON public.accounting__budgets__lines USING btree (property_id);


--
-- Name: accounting__categories_num_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__categories_num_index ON public.accounting__categories USING btree (num);


--
-- Name: accounting__charges_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__charges_account_id_index ON public.accounting__charges USING btree (account_id);


--
-- Name: accounting__charges_charge_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__charges_charge_id_index ON public.accounting__charges USING btree (charge_id);


--
-- Name: accounting__charges_image_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__charges_image_id_index ON public.accounting__charges USING btree (image_id);


--
-- Name: accounting__charges_lease_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__charges_lease_id_index ON public.accounting__charges USING btree (lease_id);


--
-- Name: accounting__charges_nsf_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__charges_nsf_id_index ON public.accounting__charges USING btree (nsf_id);


--
-- Name: accounting__charges_reversal_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__charges_reversal_id_index ON public.accounting__charges USING btree (reversal_id);


--
-- Name: accounting__checks_applicant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__checks_applicant_id_index ON public.accounting__checks USING btree (applicant_id);


--
-- Name: accounting__checks_bank_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__checks_bank_account_id_index ON public.accounting__checks USING btree (bank_account_id);


--
-- Name: accounting__checks_charge_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__checks_charge_id_index ON public.accounting__checks USING btree (charge_id);


--
-- Name: accounting__checks_document_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__checks_document_id_index ON public.accounting__checks USING btree (document_id);


--
-- Name: accounting__checks_lease_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__checks_lease_id_index ON public.accounting__checks USING btree (lease_id);


--
-- Name: accounting__checks_number_bank_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__checks_number_bank_account_id_index ON public.accounting__checks USING btree (number, bank_account_id);


--
-- Name: accounting__checks_payee_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__checks_payee_id_index ON public.accounting__checks USING btree (payee_id);


--
-- Name: accounting__checks_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__checks_tenant_id_index ON public.accounting__checks USING btree (tenant_id);


--
-- Name: accounting__closings_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__closings_admin_id_index ON public.accounting__closings USING btree (admin_id);


--
-- Name: accounting__closings_month_property_id_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__closings_month_property_id_type_index ON public.accounting__closings USING btree (month, property_id, type);


--
-- Name: accounting__entities_property_id_bank_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__entities_property_id_bank_account_id_index ON public.accounting__entities USING btree (property_id, bank_account_id);


--
-- Name: accounting__invoice_payments_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__invoice_payments_account_id_index ON public.accounting__invoice_payments USING btree (account_id);


--
-- Name: accounting__invoice_payments_check_id_invoicing_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__invoice_payments_check_id_invoicing_id_index ON public.accounting__invoice_payments USING btree (check_id, invoicing_id);


--
-- Name: accounting__invoices_document_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__invoices_document_id_index ON public.accounting__invoices USING btree (document_id);


--
-- Name: accounting__invoices_number_payee_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__invoices_number_payee_id_index ON public.accounting__invoices USING btree (number, payee_id);


--
-- Name: accounting__invoices_payee_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__invoices_payee_id_index ON public.accounting__invoices USING btree (payee_id);


--
-- Name: accounting__invoicings_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__invoicings_account_id_index ON public.accounting__invoicings USING btree (account_id);


--
-- Name: accounting__invoicings_invoice_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__invoicings_invoice_id_index ON public.accounting__invoicings USING btree (invoice_id);


--
-- Name: accounting__invoicings_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__invoicings_property_id_index ON public.accounting__invoicings USING btree (property_id);


--
-- Name: accounting__journal_entries_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__journal_entries_account_id_index ON public.accounting__journal_entries USING btree (account_id);


--
-- Name: accounting__journal_entries_page_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__journal_entries_page_id_index ON public.accounting__journal_entries USING btree (page_id);


--
-- Name: accounting__journal_entries_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__journal_entries_property_id_index ON public.accounting__journal_entries USING btree (property_id);


--
-- Name: accounting__payment_nsfs_payment_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__payment_nsfs_payment_id_index ON public.accounting__payment_nsfs USING btree (payment_id);


--
-- Name: accounting__payment_nsfs_proof_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__payment_nsfs_proof_id_index ON public.accounting__payment_nsfs USING btree (proof_id);


--
-- Name: accounting__payments_batch_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__payments_batch_id_index ON public.accounting__payments USING btree (batch_id);


--
-- Name: accounting__payments_image_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__payments_image_id_index ON public.accounting__payments USING btree (image_id);


--
-- Name: accounting__payments_lease_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__payments_lease_id_index ON public.accounting__payments USING btree (lease_id);


--
-- Name: accounting__payments_payment_source_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__payments_payment_source_id_index ON public.accounting__payments USING btree (payment_source_id);


--
-- Name: accounting__payments_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__payments_property_id_index ON public.accounting__payments USING btree (property_id);


--
-- Name: accounting__payments_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__payments_tenant_id_index ON public.accounting__payments USING btree (tenant_id);


--
-- Name: accounting__payments_transaction_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__payments_transaction_id_index ON public.accounting__payments USING btree (transaction_id) WHERE ((description = 'Money Order'::text) OR (description = 'MoneyGram Payment'::text));


--
-- Name: accounting__receipts_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting__receipts_account_id_index ON public.accounting__receipts USING btree (account_id);


--
-- Name: accounting__receipts_charge_id_concession_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__receipts_charge_id_concession_id_index ON public.accounting__receipts USING btree (charge_id, concession_id, start_date, stop_date);


--
-- Name: accounting__receipts_charge_id_payment_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__receipts_charge_id_payment_id_index ON public.accounting__receipts USING btree (charge_id, payment_id, start_date, stop_date);


--
-- Name: accounting__reconciliations_batch_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__reconciliations_batch_id_index ON public.accounting__reconciliations USING btree (batch_id);


--
-- Name: accounting__reconciliations_check_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__reconciliations_check_id_index ON public.accounting__reconciliations USING btree (check_id);


--
-- Name: accounting__reconciliations_journal_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__reconciliations_journal_id_index ON public.accounting__reconciliations USING btree (journal_id);


--
-- Name: accounting__reconciliations_payment_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__reconciliations_payment_id_index ON public.accounting__reconciliations USING btree (payment_id);


--
-- Name: accounting__registers_property_id_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__registers_property_id_account_id_index ON public.accounting__registers USING btree (property_id, account_id);


--
-- Name: accounting__registers_property_id_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__registers_property_id_type_index ON public.accounting__registers USING btree (property_id, type) WHERE (is_default = true);


--
-- Name: accounting__report_templates_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__report_templates_name_index ON public.accounting__report_templates USING btree (name);


--
-- Name: accounting__requests_admin_id_charge_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__requests_admin_id_charge_id_index ON public.accounting__requests USING btree (admin_id, charge_id);


--
-- Name: accounting__requests_admin_id_payment_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting__requests_admin_id_payment_id_index ON public.accounting__requests USING btree (admin_id, payment_id);


--
-- Name: accounts__accounts_profile_pic_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts__accounts_profile_pic_id_index ON public.accounts__accounts USING btree (profile_pic_id);


--
-- Name: accounts__accounts_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts__accounts_tenant_id_index ON public.accounts__accounts USING btree (tenant_id);


--
-- Name: accounts__accounts_tenant_id_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts__accounts_tenant_id_property_id_index ON public.accounts__accounts USING btree (tenant_id, property_id);


--
-- Name: accounts__accounts_username_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts__accounts_username_index ON public.accounts__accounts USING btree (username);


--
-- Name: accounts__accounts_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts__accounts_uuid_index ON public.accounts__accounts USING btree (uuid);


--
-- Name: accounts__autopays_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts__autopays_account_id_index ON public.accounts__autopays USING btree (account_id);


--
-- Name: accounts__autopays_payment_source_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts__autopays_payment_source_id_index ON public.accounts__autopays USING btree (payment_source_id);


--
-- Name: accounts__banks_routing_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts__banks_routing_index ON public.settings__banks USING btree (routing);


--
-- Name: accounts__locks_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts__locks_account_id_index ON public.accounts__locks USING btree (account_id);


--
-- Name: accounts__locks_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts__locks_admin_id_index ON public.accounts__locks USING btree (admin_id);


--
-- Name: accounts__logins_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts__logins_account_id_index ON public.accounts__logins USING btree (account_id);


--
-- Name: accounts__payment_sources_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounts__payment_sources_account_id_index ON public.accounts__payment_sources USING btree (account_id);


--
-- Name: admins__actions_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__actions_admin_id_index ON public.admins__actions USING btree (admin_id);


--
-- Name: admins__admins_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admins__admins_email_index ON public.admins__admins USING btree (email);


--
-- Name: admins__admins_username_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admins__admins_username_index ON public.admins__admins USING btree (username);


--
-- Name: admins__admins_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admins__admins_uuid_index ON public.admins__admins USING btree (uuid);


--
-- Name: admins__alerts_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__alerts_admin_id_index ON public.admins__alerts USING btree (admin_id);


--
-- Name: admins__approval_logs_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__approval_logs_admin_id_index ON public.admins__approval_logs USING btree (admin_id);


--
-- Name: admins__approval_logs_approval_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__approval_logs_approval_id_index ON public.admins__approval_logs USING btree (approval_id);


--
-- Name: admins__approvals_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__approvals_admin_id_index ON public.admins__approvals USING btree (admin_id);


--
-- Name: admins__approvals_costs_approval_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__approvals_costs_approval_id_index ON public.admins__approvals_costs USING btree (approval_id);


--
-- Name: admins__approvals_costs_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__approvals_costs_category_id_index ON public.admins__approvals_costs USING btree (category_id);


--
-- Name: admins__approvals_notes_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__approvals_notes_admin_id_index ON public.admins__approvals_notes USING btree (admin_id);


--
-- Name: admins__approvals_notes_approval_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__approvals_notes_approval_id_index ON public.admins__approvals_notes USING btree (approval_id);


--
-- Name: admins__approvals_num_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admins__approvals_num_type_index ON public.admins__approvals USING btree (num, type);


--
-- Name: admins__approvals_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__approvals_property_id_index ON public.admins__approvals USING btree (property_id);


--
-- Name: admins__device_auths_device_id_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admins__device_auths_device_id_property_id_index ON public.admins__device_auths USING btree (device_id, property_id);


--
-- Name: admins__devices_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admins__devices_name_index ON public.admins__devices USING btree (name);


--
-- Name: admins__entities_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admins__entities_name_index ON public.admins__entities USING btree (name);


--
-- Name: admins__messages_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__messages_admin_id_index ON public.admins__messages USING btree (admin_id);


--
-- Name: admins__org_charts_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admins__org_charts_admin_id_index ON public.admins__org_charts USING btree (admin_id);


--
-- Name: admins__permissions_admin_id_entity_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admins__permissions_admin_id_entity_id_index ON public.admins__permissions USING btree (admin_id, entity_id);


--
-- Name: admins__permissions_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__permissions_admin_id_index ON public.admins__permissions USING btree (admin_id);


--
-- Name: admins__permissions_entity_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admins__permissions_entity_id_index ON public.admins__permissions USING btree (entity_id);


--
-- Name: admins__profiles_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX admins__profiles_admin_id_index ON public.admins__profiles USING btree (admin_id);


--
-- Name: chat__messages_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat__messages_admin_id_index ON public.chat__messages USING btree (admin_id);


--
-- Name: chat__messages_attachment_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat__messages_attachment_id_index ON public.chat__messages USING btree (attachment_id);


--
-- Name: chat__messages_reply_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat__messages_reply_id_index ON public.chat__messages USING btree (reply_id);


--
-- Name: chat__messages_room_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat__messages_room_id_index ON public.chat__messages USING btree (room_id);


--
-- Name: chat__read_receipts_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat__read_receipts_admin_id_index ON public.chat__read_receipts USING btree (admin_id);


--
-- Name: chat__read_receipts_message_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat__read_receipts_message_id_index ON public.chat__read_receipts USING btree (message_id);


--
-- Name: chat__read_receipts_room_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat__read_receipts_room_id_index ON public.chat__read_receipts USING btree (room_id);


--
-- Name: chat__room_members_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat__room_members_admin_id_index ON public.chat__room_members USING btree (admin_id);


--
-- Name: chat__room_members_room_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat__room_members_room_id_index ON public.chat__room_members USING btree (room_id);


--
-- Name: chat__rooms_image_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat__rooms_image_id_index ON public.chat__rooms USING btree (image_id);


--
-- Name: data__uploads_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX data__uploads_uuid_index ON public.data__uploads USING btree (uuid);


--
-- Name: exports__categories_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX exports__categories_admin_id_index ON public.exports__categories USING btree (admin_id);


--
-- Name: exports__documents_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX exports__documents_category_id_index ON public.exports__documents USING btree (category_id);


--
-- Name: exports__documents_document_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX exports__documents_document_id_index ON public.exports__documents USING btree (document_id);


--
-- Name: exports__recipients_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX exports__recipients_admin_id_index ON public.exports__recipients USING btree (admin_id);


--
-- Name: leases__custom_packages_renewal_package_id_lease_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX leases__custom_packages_renewal_package_id_lease_id_index ON public.leases__custom_packages USING btree (renewal_package_id, lease_id);


--
-- Name: leases__forms_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX leases__forms_application_id_index ON public.leases__forms USING btree (application_id);


--
-- Name: leases__forms_document_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leases__forms_document_id_index ON public.leases__forms USING btree (document_id);


--
-- Name: leases__forms_lease_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX leases__forms_lease_id_index ON public.leases__forms USING btree (lease_id);


--
-- Name: leases__leases_document_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leases__leases_document_id_index ON public.leases__leases USING btree (document_id);


--
-- Name: leases__leases_move_out_reason_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leases__leases_move_out_reason_id_index ON public.leases__leases USING btree (move_out_reason_id);


--
-- Name: leases__leases_renewal_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leases__leases_renewal_id_index ON public.leases__leases USING btree (renewal_id);


--
-- Name: leases__screenings_lease_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leases__screenings_lease_id_index ON public.leases__screenings USING btree (lease_id);


--
-- Name: leases__screenings_person_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX leases__screenings_person_id_index ON public.leases__screenings USING btree (person_id);


--
-- Name: leases__screenings_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leases__screenings_property_id_index ON public.leases__screenings USING btree (property_id);


--
-- Name: leases__screenings_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX leases__screenings_tenant_id_index ON public.leases__screenings USING btree (tenant_id);


--
-- Name: maintenance__assignments_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__assignments_admin_id_index ON public.maintenance__assignments USING btree (admin_id);


--
-- Name: maintenance__assignments_order_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__assignments_order_id_index ON public.maintenance__assignments USING btree (order_id);


--
-- Name: maintenance__assignments_tech_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__assignments_tech_id_index ON public.maintenance__assignments USING btree (tech_id);


--
-- Name: maintenance__card_items_card_id_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX maintenance__card_items_card_id_name_index ON public.maintenance__card_items USING btree (card_id, name);


--
-- Name: maintenance__card_items_tech_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__card_items_tech_id_index ON public.maintenance__card_items USING btree (tech_id);


--
-- Name: maintenance__cards_lease_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX maintenance__cards_lease_id_index ON public.maintenance__cards USING btree (lease_id);


--
-- Name: maintenance__categories_name_path_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX maintenance__categories_name_path_index ON public.maintenance__categories USING btree (name, path);


--
-- Name: maintenance__inventory_logs_material_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__inventory_logs_material_id_index ON public.maintenance__inventory_logs USING btree (material_id);


--
-- Name: maintenance__jobs_property_id_tech_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX maintenance__jobs_property_id_tech_id_index ON public.maintenance__jobs USING btree (property_id, tech_id);


--
-- Name: maintenance__notes_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__notes_admin_id_index ON public.maintenance__notes USING btree (admin_id);


--
-- Name: maintenance__notes_order_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__notes_order_id_index ON public.maintenance__notes USING btree (order_id);


--
-- Name: maintenance__notes_tech_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__notes_tech_id_index ON public.maintenance__notes USING btree (tech_id);


--
-- Name: maintenance__notes_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__notes_tenant_id_index ON public.maintenance__notes USING btree (tenant_id);


--
-- Name: maintenance__offers_tech_id_order_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX maintenance__offers_tech_id_order_id_index ON public.maintenance__offers USING btree (tech_id, order_id);


--
-- Name: maintenance__orders_card_item_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX maintenance__orders_card_item_id_index ON public.maintenance__orders USING btree (card_item_id);


--
-- Name: maintenance__orders_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__orders_category_id_index ON public.maintenance__orders USING btree (category_id);


--
-- Name: maintenance__orders_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__orders_property_id_index ON public.maintenance__orders USING btree (property_id);


--
-- Name: maintenance__orders_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__orders_tenant_id_index ON public.maintenance__orders USING btree (tenant_id);


--
-- Name: maintenance__orders_unit_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__orders_unit_id_index ON public.maintenance__orders USING btree (unit_id);


--
-- Name: maintenance__orders_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX maintenance__orders_uuid_index ON public.maintenance__orders USING btree (uuid);


--
-- Name: maintenance__paid_time_tech_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__paid_time_tech_id_index ON public.maintenance__paid_time USING btree (tech_id);


--
-- Name: maintenance__parts_order_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__parts_order_id_index ON public.maintenance__parts USING btree (order_id);


--
-- Name: maintenance__presence_logs_tech_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__presence_logs_tech_id_index ON public.maintenance__presence_logs USING btree (tech_id);


--
-- Name: maintenance__recurring_orders_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__recurring_orders_property_id_index ON public.maintenance__recurring_orders USING btree (property_id);


--
-- Name: maintenance__skills_tech_id_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX maintenance__skills_tech_id_category_id_index ON public.maintenance__skills USING btree (tech_id, category_id);


--
-- Name: maintenance__techs_identifier_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX maintenance__techs_identifier_index ON public.maintenance__techs USING btree (identifier);


--
-- Name: maintenance__techs_image_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__techs_image_id_index ON public.maintenance__techs USING btree (image_id);


--
-- Name: maintenance__techs_pass_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX maintenance__techs_pass_code_index ON public.maintenance__techs USING btree (pass_code);


--
-- Name: maintenance__timecards_tech_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maintenance__timecards_tech_id_index ON public.maintenance__timecards USING btree (tech_id);


--
-- Name: materials__inventory_material_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials__inventory_material_id_index ON public.materials__inventory USING btree (material_id);


--
-- Name: materials__inventory_stock_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials__inventory_stock_id_index ON public.materials__inventory USING btree (stock_id);


--
-- Name: materials__material_types_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX materials__material_types_name_index ON public.materials__types USING btree (name);


--
-- Name: materials__materials_image_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials__materials_image_id_index ON public.materials__materials USING btree (image_id);


--
-- Name: materials__stocks_image_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials__stocks_image_id_index ON public.materials__stocks USING btree (image_id);


--
-- Name: materials__stocks_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX materials__stocks_name_index ON public.materials__stocks USING btree (name);


--
-- Name: materials__toolbox_items_material_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials__toolbox_items_material_id_index ON public.materials__toolbox_items USING btree (material_id);


--
-- Name: materials__toolbox_items_stock_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials__toolbox_items_stock_id_index ON public.materials__toolbox_items USING btree (stock_id);


--
-- Name: materials__toolbox_items_tech_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials__toolbox_items_tech_id_index ON public.materials__toolbox_items USING btree (tech_id);


--
-- Name: materials__warehouses_image_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX materials__warehouses_image_id_index ON public.materials__warehouses USING btree (image_id);


--
-- Name: messaging__emails_body_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messaging__emails_body_id_index ON public.messaging__emails USING btree (body_id);


--
-- Name: messaging__emails_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messaging__emails_tenant_id_index ON public.messaging__emails USING btree (tenant_id);


--
-- Name: messaging__inboxes_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX messaging__inboxes_admin_id_index ON public.messaging__inboxes USING btree (admin_id);


--
-- Name: messaging__mail_addresses_address_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX messaging__mail_addresses_address_index ON public.messaging__mail_addresses USING btree (address);


--
-- Name: messaging__property_templates_property_id_template_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX messaging__property_templates_property_id_template_id_index ON public.messaging__property_templates USING btree (property_id, template_id);


--
-- Name: messaging__routes_mail_address_id_inbox_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX messaging__routes_mail_address_id_inbox_id_index ON public.messaging__routes USING btree (mail_address_id, inbox_id);


--
-- Name: properties__charges_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__charges_account_id_index ON public.properties__charges USING btree (account_id);


--
-- Name: properties__charges_lease_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__charges_lease_id_index ON public.properties__charges USING btree (lease_id);


--
-- Name: properties__documents_document_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__documents_document_id_index ON public.properties__documents USING btree (document_id);


--
-- Name: properties__documents_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__documents_tenant_id_index ON public.properties__documents USING btree (tenant_id);


--
-- Name: properties__evictions_lease_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__evictions_lease_id_index ON public.properties__evictions USING btree (lease_id);


--
-- Name: properties__features_property_id_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__features_property_id_name_index ON public.properties__features USING btree (property_id, name) WHERE (stop_date IS NULL);


--
-- Name: properties__floor_plan_features_feature_id_floor_plan_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__floor_plan_features_feature_id_floor_plan_id_index ON public.properties__floor_plan_features USING btree (feature_id, floor_plan_id);


--
-- Name: properties__floor_plans_property_id_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__floor_plans_property_id_name_index ON public.properties__floor_plans USING btree (property_id, name);


--
-- Name: properties__insurances_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__insurances_tenant_id_index ON public.properties__insurances USING btree (tenant_id);


--
-- Name: properties__letter_templates_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__letter_templates_property_id_index ON public.properties__letter_templates USING btree (property_id);


--
-- Name: properties__occupancies_tenant_id_lease_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__occupancies_tenant_id_lease_id_index ON public.properties__occupancies USING btree (tenant_id, lease_id);


--
-- Name: properties__packages_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__packages_tenant_id_index ON public.properties__packages USING btree (tenant_id);


--
-- Name: properties__packages_unit_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__packages_unit_id_index ON public.properties__packages USING btree (unit_id);


--
-- Name: properties__phone__lines_number_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__phone__lines_number_index ON public.properties__phone__lines USING btree (number);


--
-- Name: properties__phone__lines_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__phone__lines_property_id_index ON public.properties__phone__lines USING btree (property_id);


--
-- Name: properties__processors_property_id_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__processors_property_id_type_index ON public.properties__processors USING btree (property_id, type);


--
-- Name: properties__properties_banner_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__properties_banner_id_index ON public.properties__properties USING btree (banner_id);


--
-- Name: properties__properties_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__properties_code_index ON public.properties__properties USING btree (code);


--
-- Name: properties__properties_icon_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__properties_icon_id_index ON public.properties__properties USING btree (icon_id);


--
-- Name: properties__properties_logo_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__properties_logo_id_index ON public.properties__properties USING btree (logo_id);


--
-- Name: properties__properties_region_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__properties_region_id_index ON public.properties__properties USING btree (region_id);


--
-- Name: properties__properties_stock_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__properties_stock_id_index ON public.properties__properties USING btree (stock_id);


--
-- Name: properties__property_admin_documents_property_id_admin_document; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__property_admin_documents_property_id_admin_document ON public.properties__property_admin_documents USING btree (property_id, admin_document_id);


--
-- Name: properties__recurring_letters_letter_template_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__recurring_letters_letter_template_id_index ON public.properties__recurring_letters USING btree (letter_template_id);


--
-- Name: properties__regions_regional_supervisor_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__regions_regional_supervisor_id_index ON public.properties__regions USING btree (regional_supervisor_id);


--
-- Name: properties__resident_event_attendances_resident_event_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__resident_event_attendances_resident_event_id_index ON public.properties__resident_event_attendances USING btree (resident_event_id);


--
-- Name: properties__resident_event_attendances_resident_event_id_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__resident_event_attendances_resident_event_id_tenant ON public.properties__resident_event_attendances USING btree (resident_event_id, tenant_id);


--
-- Name: properties__resident_event_attendances_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__resident_event_attendances_tenant_id_index ON public.properties__resident_event_attendances USING btree (tenant_id);


--
-- Name: properties__resident_events_attachment_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__resident_events_attachment_id_index ON public.properties__resident_events USING btree (attachment_id);


--
-- Name: properties__resident_events_image_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__resident_events_image_id_index ON public.properties__resident_events USING btree (image_id);


--
-- Name: properties__resident_events_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__resident_events_property_id_index ON public.properties__resident_events USING btree (property_id);


--
-- Name: properties__scopings_property_id_entity_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__scopings_property_id_entity_id_index ON public.properties__scopings USING btree (property_id, entity_id);


--
-- Name: properties__settings_default_bank_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__settings_default_bank_account_id_index ON public.properties__settings USING btree (default_bank_account_id);


--
-- Name: properties__settings_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__settings_property_id_index ON public.properties__settings USING btree (property_id);


--
-- Name: properties__unit_features_unit_id_feature_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__unit_features_unit_id_feature_id_index ON public.properties__unit_features USING btree (unit_id, feature_id);


--
-- Name: properties__units_floor_plan_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__units_floor_plan_id_index ON public.properties__units USING btree (floor_plan_id);


--
-- Name: properties__units_property_id_number_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__units_property_id_number_index ON public.properties__units USING btree (property_id, number);


--
-- Name: properties__units_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX properties__units_uuid_index ON public.properties__units USING btree (uuid);


--
-- Name: properties__visits_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__visits_property_id_index ON public.properties__visits USING btree (property_id);


--
-- Name: properties__visits_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX properties__visits_tenant_id_index ON public.properties__visits USING btree (tenant_id);


--
-- Name: prospects__closures_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prospects__closures_property_id_index ON public.prospects__closures USING btree (property_id);


--
-- Name: prospects__memos_prospect_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prospects__memos_prospect_id_index ON public.prospects__memos USING btree (prospect_id);


--
-- Name: prospects__openings_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prospects__openings_property_id_index ON public.prospects__openings USING btree (property_id);


--
-- Name: prospects__prospects_admin_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prospects__prospects_admin_id_index ON public.prospects__prospects USING btree (admin_id);


--
-- Name: prospects__prospects_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prospects__prospects_property_id_index ON public.prospects__prospects USING btree (property_id);


--
-- Name: prospects__prospects_traffic_source_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prospects__prospects_traffic_source_id_index ON public.prospects__prospects USING btree (traffic_source_id);


--
-- Name: prospects__showings_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prospects__showings_property_id_index ON public.prospects__showings USING btree (property_id);


--
-- Name: prospects__showings_prospect_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prospects__showings_prospect_id_index ON public.prospects__showings USING btree (prospect_id);


--
-- Name: prospects__showings_unit_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prospects__showings_unit_id_index ON public.prospects__showings USING btree (unit_id);


--
-- Name: rent_apply__documents_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__documents_application_id_index ON public.rent_apply__documents USING btree (application_id);


--
-- Name: rent_apply__documents_url_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__documents_url_id_index ON public.rent_apply__documents USING btree (url_id);


--
-- Name: rent_apply__emergency_contacts_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__emergency_contacts_application_id_index ON public.rent_apply__emergency_contacts USING btree (application_id);


--
-- Name: rent_apply__employments_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__employments_application_id_index ON public.rent_apply__employments USING btree (application_id);


--
-- Name: rent_apply__employments_person_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__employments_person_id_index ON public.rent_apply__employments USING btree (person_id);


--
-- Name: rent_apply__histories_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__histories_application_id_index ON public.rent_apply__histories USING btree (application_id);


--
-- Name: rent_apply__incomes_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__incomes_application_id_index ON public.rent_apply__incomes USING btree (application_id);


--
-- Name: rent_apply__memos_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__memos_application_id_index ON public.rent_apply__memos USING btree (application_id);


--
-- Name: rent_apply__move_ins_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__move_ins_application_id_index ON public.rent_apply__move_ins USING btree (application_id);


--
-- Name: rent_apply__move_ins_floor_plan_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__move_ins_floor_plan_id_index ON public.rent_apply__move_ins USING btree (floor_plan_id);


--
-- Name: rent_apply__persons_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__persons_application_id_index ON public.rent_apply__persons USING btree (application_id);


--
-- Name: rent_apply__pets_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__pets_application_id_index ON public.rent_apply__pets USING btree (application_id);


--
-- Name: rent_apply__rent_applications_device_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__rent_applications_device_id_index ON public.rent_apply__rent_applications USING btree (device_id);


--
-- Name: rent_apply__rent_applications_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__rent_applications_property_id_index ON public.rent_apply__rent_applications USING btree (property_id);


--
-- Name: rent_apply__saved_forms_email_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX rent_apply__saved_forms_email_property_id_index ON public.rent_apply__saved_forms USING btree (email, property_id);


--
-- Name: rent_apply__vehicles_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rent_apply__vehicles_application_id_index ON public.rent_apply__vehicles USING btree (application_id);


--
-- Name: rewards__awards_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rewards__awards_tenant_id_index ON public.rewards__awards USING btree (tenant_id);


--
-- Name: rewards__awards_type_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rewards__awards_type_id_index ON public.rewards__awards USING btree (type_id);


--
-- Name: rewards__prizes_icon_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rewards__prizes_icon_id_index ON public.rewards__prizes USING btree (icon_id);


--
-- Name: rewards__purchases_prize_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rewards__purchases_prize_id_index ON public.rewards__purchases USING btree (prize_id);


--
-- Name: rewards__purchases_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rewards__purchases_property_id_index ON public.rewards__purchases USING btree (property_id);


--
-- Name: rewards__purchases_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rewards__purchases_tenant_id_index ON public.rewards__purchases USING btree (tenant_id);


--
-- Name: rewards__types_icon_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rewards__types_icon_id_index ON public.rewards__types USING btree (icon_id);


--
-- Name: rewards__types_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX rewards__types_name_index ON public.rewards__types USING btree (name);


--
-- Name: settings__banks_routing_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings__banks_routing_index ON public.settings__banks USING btree (routing);


--
-- Name: settings__damages_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings__damages_name_index ON public.settings__damages USING btree (name);


--
-- Name: settings__move_out_reasons_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings__move_out_reasons_name_index ON public.settings__move_out_reasons USING btree (name);


--
-- Name: social__posts_likes_post_id_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX social__posts_likes_post_id_tenant_id_index ON public.social__posts_likes USING btree (post_id, tenant_id);


--
-- Name: tenants__pets_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tenants__pets_tenant_id_index ON public.tenants__pets USING btree (tenant_id);


--
-- Name: tenants__tenants_application_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tenants__tenants_application_id_index ON public.tenants__tenants USING btree (application_id);


--
-- Name: tenants__tenants_first_name_last_name_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX tenants__tenants_first_name_last_name_email_index ON public.tenants__tenants USING btree (first_name, last_name, email);


--
-- Name: tenants__tenants_uuid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX tenants__tenants_uuid_index ON public.tenants__tenants USING btree (uuid);


--
-- Name: tenants__vehicles_tenant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tenants__vehicles_tenant_id_index ON public.tenants__vehicles USING btree (tenant_id);


--
-- Name: unique_month_year; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_month_year ON public.accounting__budgets__lines USING btree (account_id, property_id, month);


--
-- Name: units__default_lease_charges_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX units__default_lease_charges_account_id_index ON public.units__default_lease_charges USING btree (account_id);


--
-- Name: units__default_lease_charges_floor_plan_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX units__default_lease_charges_floor_plan_id_index ON public.units__default_lease_charges USING btree (floor_plan_id);


--
-- Name: vendor__properties_vendor_id_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX vendor__properties_vendor_id_property_id_index ON public.vendor__properties USING btree (vendor_id, property_id);


--
-- Name: vendors__orders_property_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vendors__orders_property_id_index ON public.vendors__orders USING btree (property_id);


--
-- Name: vendors__skills_vendor_id_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX vendors__skills_vendor_id_category_id_index ON public.vendors__skills USING btree (vendor_id, category_id);


--
-- Name: accounting__invoice_payments accounting__invoice_payments_delete; Type: RULE; Schema: public; Owner: -
--

CREATE RULE accounting__invoice_payments_delete AS
    ON DELETE TO public.accounting__invoice_payments
   WHERE (old.reconciliation_id IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: accounting__payments accounting__payments_delete; Type: RULE; Schema: public; Owner: -
--

CREATE RULE accounting__payments_delete AS
    ON DELETE TO public.accounting__payments
   WHERE (old.reconciliation_id IS NOT NULL) DO INSTEAD NOTHING;


--
-- Name: accounting__reconciliation_postings accounting__reconciliation_postings_undo; Type: RULE; Schema: public; Owner: -
--

CREATE RULE accounting__reconciliation_postings_undo AS
    ON DELETE TO public.accounting__reconciliation_postings
   WHERE old.is_posted DO INSTEAD NOTHING;


--
-- Name: accounting__charges charge_update_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER charge_update_trigger AFTER INSERT OR DELETE OR UPDATE ON public.accounting__charges FOR EACH ROW EXECUTE FUNCTION public.post_charge_hook();


--
-- Name: accounting__payments payment_update_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER payment_update_trigger AFTER INSERT OR UPDATE ON public.accounting__payments FOR EACH ROW EXECUTE FUNCTION public.post_payment_hook();


--
-- Name: accounting__accounts accounting__accounts_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__accounts
    ADD CONSTRAINT accounting__accounts_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.accounting__categories(id) ON DELETE CASCADE;


--
-- Name: accounting__bank_accounts accounting__bank_accounts_cash_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__bank_accounts
    ADD CONSTRAINT accounting__bank_accounts_cash_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounting__accounts(id) ON DELETE CASCADE;


--
-- Name: accounting__batches accounting__batches_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__batches
    ADD CONSTRAINT accounting__batches_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES public.accounting__bank_accounts(id);


--
-- Name: accounting__batches accounting__batches_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__batches
    ADD CONSTRAINT accounting__batches_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id);


--
-- Name: accounting__budgets__imports accounting__budgets__imports_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__budgets__imports
    ADD CONSTRAINT accounting__budgets__imports_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE SET NULL;


--
-- Name: accounting__budgets__imports accounting__budgets__imports_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__budgets__imports
    ADD CONSTRAINT accounting__budgets__imports_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: accounting__budgets__imports accounting__budgets__imports_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__budgets__imports
    ADD CONSTRAINT accounting__budgets__imports_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: accounting__budgets__lines accounting__budgets__lines_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__budgets__lines
    ADD CONSTRAINT accounting__budgets__lines_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounting__accounts(id);


--
-- Name: accounting__budgets__lines accounting__budgets__lines_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__budgets__lines
    ADD CONSTRAINT accounting__budgets__lines_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id);


--
-- Name: accounting__budgets__lines accounting__budgets__lines_import_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__budgets__lines
    ADD CONSTRAINT accounting__budgets__lines_import_id_fkey FOREIGN KEY (import_id) REFERENCES public.accounting__budgets__imports(id);


--
-- Name: accounting__budgets__lines accounting__budgets__lines_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__budgets__lines
    ADD CONSTRAINT accounting__budgets__lines_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id);


--
-- Name: accounting__charges accounting__charges_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__charges
    ADD CONSTRAINT accounting__charges_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounting__accounts(id);


--
-- Name: accounting__charges accounting__charges_charge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__charges
    ADD CONSTRAINT accounting__charges_charge_id_fkey FOREIGN KEY (charge_id) REFERENCES public.properties__charges(id) ON DELETE SET NULL;


--
-- Name: accounting__charges accounting__charges_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__charges
    ADD CONSTRAINT accounting__charges_image_id_fkey FOREIGN KEY (image_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: accounting__charges accounting__charges_lease_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__charges
    ADD CONSTRAINT accounting__charges_lease_id_fkey FOREIGN KEY (lease_id) REFERENCES public.leases__leases(id) ON DELETE CASCADE;


--
-- Name: accounting__charges accounting__charges_nsf_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__charges
    ADD CONSTRAINT accounting__charges_nsf_id_fkey FOREIGN KEY (nsf_id) REFERENCES public.accounting__payments(id) ON DELETE CASCADE;


--
-- Name: accounting__charges accounting__charges_reversal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__charges
    ADD CONSTRAINT accounting__charges_reversal_id_fkey FOREIGN KEY (reversal_id) REFERENCES public.accounting__charges(id) ON DELETE SET NULL;


--
-- Name: accounting__checks accounting__checks_applicant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__checks
    ADD CONSTRAINT accounting__checks_applicant_id_fkey FOREIGN KEY (applicant_id) REFERENCES public.rent_apply__persons(id) ON DELETE CASCADE;


--
-- Name: accounting__checks accounting__checks_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__checks
    ADD CONSTRAINT accounting__checks_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES public.accounting__bank_accounts(id) ON DELETE CASCADE;


--
-- Name: accounting__checks accounting__checks_charge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__checks
    ADD CONSTRAINT accounting__checks_charge_id_fkey FOREIGN KEY (charge_id) REFERENCES public.accounting__charges(id) ON DELETE CASCADE;


--
-- Name: accounting__checks accounting__checks_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__checks
    ADD CONSTRAINT accounting__checks_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: accounting__checks accounting__checks_lease_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__checks
    ADD CONSTRAINT accounting__checks_lease_id_fkey FOREIGN KEY (lease_id) REFERENCES public.leases__leases(id) ON DELETE CASCADE;


--
-- Name: accounting__checks accounting__checks_payee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__checks
    ADD CONSTRAINT accounting__checks_payee_id_fkey FOREIGN KEY (payee_id) REFERENCES public.accounting__payees(id) ON DELETE CASCADE;


--
-- Name: accounting__checks accounting__checks_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__checks
    ADD CONSTRAINT accounting__checks_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: accounting__closings accounting__closings_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__closings
    ADD CONSTRAINT accounting__closings_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE SET NULL;


--
-- Name: accounting__closings accounting__closings_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__closings
    ADD CONSTRAINT accounting__closings_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: accounting__entities accounting__entities_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__entities
    ADD CONSTRAINT accounting__entities_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES public.accounting__bank_accounts(id) ON DELETE CASCADE;


--
-- Name: accounting__entities accounting__entities_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__entities
    ADD CONSTRAINT accounting__entities_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: accounting__invoice_payments accounting__invoice_payments_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoice_payments
    ADD CONSTRAINT accounting__invoice_payments_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounting__accounts(id);


--
-- Name: accounting__invoice_payments accounting__invoice_payments_check_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoice_payments
    ADD CONSTRAINT accounting__invoice_payments_check_id_fkey FOREIGN KEY (check_id) REFERENCES public.accounting__checks(id) ON DELETE SET NULL;


--
-- Name: accounting__invoice_payments accounting__invoice_payments_invoicing_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoice_payments
    ADD CONSTRAINT accounting__invoice_payments_invoicing_id_fkey FOREIGN KEY (invoicing_id) REFERENCES public.accounting__invoicings(id) ON DELETE CASCADE;


--
-- Name: accounting__invoice_payments accounting__invoice_payments_reconciliation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoice_payments
    ADD CONSTRAINT accounting__invoice_payments_reconciliation_id_fkey FOREIGN KEY (reconciliation_id) REFERENCES public.accounting__reconciliation_postings(id);


--
-- Name: accounting__invoices accounting__invoices_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoices
    ADD CONSTRAINT accounting__invoices_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: accounting__invoices accounting__invoices_payable_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoices
    ADD CONSTRAINT accounting__invoices_payable_account_id_fkey FOREIGN KEY (payable_account_id) REFERENCES public.accounting__accounts(id) ON DELETE CASCADE;


--
-- Name: accounting__invoices accounting__invoices_payee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoices
    ADD CONSTRAINT accounting__invoices_payee_id_fkey FOREIGN KEY (payee_id) REFERENCES public.accounting__payees(id) ON DELETE CASCADE;


--
-- Name: accounting__invoicings accounting__invoicings_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoicings
    ADD CONSTRAINT accounting__invoicings_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.accounting__invoices(id) ON DELETE CASCADE;


--
-- Name: accounting__invoicings accounting__invoicings_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoicings
    ADD CONSTRAINT accounting__invoicings_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: accounting__invoicings accounting__invoicings_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__invoicings
    ADD CONSTRAINT accounting__invoicings_type_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounting__accounts(id) ON DELETE CASCADE;


--
-- Name: accounting__journal_entries accounting__journal_entries_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__journal_entries
    ADD CONSTRAINT accounting__journal_entries_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounting__accounts(id) ON DELETE CASCADE;


--
-- Name: accounting__journal_entries accounting__journal_entries_page_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__journal_entries
    ADD CONSTRAINT accounting__journal_entries_page_id_fkey FOREIGN KEY (page_id) REFERENCES public.accounting__journal_pages(id) ON DELETE CASCADE;


--
-- Name: accounting__journal_entries accounting__journal_entries_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__journal_entries
    ADD CONSTRAINT accounting__journal_entries_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: accounting__payment_nsfs accounting__payment_nsfs_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payment_nsfs
    ADD CONSTRAINT accounting__payment_nsfs_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.accounting__payments(id) ON DELETE CASCADE;


--
-- Name: accounting__payment_nsfs accounting__payment_nsfs_proof_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payment_nsfs
    ADD CONSTRAINT accounting__payment_nsfs_proof_id_fkey FOREIGN KEY (proof_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: accounting__payments accounting__payments_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payments
    ADD CONSTRAINT accounting__payments_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE CASCADE;


--
-- Name: accounting__payments accounting__payments_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payments
    ADD CONSTRAINT accounting__payments_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.accounting__batches(id) ON DELETE SET NULL;


--
-- Name: accounting__payments accounting__payments_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payments
    ADD CONSTRAINT accounting__payments_image_id_fkey FOREIGN KEY (image_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: accounting__payments accounting__payments_lease_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payments
    ADD CONSTRAINT accounting__payments_lease_id_fkey FOREIGN KEY (lease_id) REFERENCES public.leases__leases(id) ON DELETE SET NULL;


--
-- Name: accounting__payments accounting__payments_payment_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payments
    ADD CONSTRAINT accounting__payments_payment_source_id_fkey FOREIGN KEY (payment_source_id) REFERENCES public.accounts__payment_sources(id) ON DELETE SET NULL;


--
-- Name: accounting__payments accounting__payments_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payments
    ADD CONSTRAINT accounting__payments_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: accounting__payments accounting__payments_reconciliation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payments
    ADD CONSTRAINT accounting__payments_reconciliation_id_fkey FOREIGN KEY (reconciliation_id) REFERENCES public.accounting__reconciliation_postings(id);


--
-- Name: accounting__payments accounting__payments_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__payments
    ADD CONSTRAINT accounting__payments_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE SET NULL;


--
-- Name: accounting__receipts accounting__receipts_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__receipts
    ADD CONSTRAINT accounting__receipts_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounting__accounts(id);


--
-- Name: accounting__receipts accounting__receipts_charge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__receipts
    ADD CONSTRAINT accounting__receipts_charge_id_fkey FOREIGN KEY (charge_id) REFERENCES public.accounting__charges(id) ON DELETE CASCADE;


--
-- Name: accounting__receipts accounting__receipts_concession_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__receipts
    ADD CONSTRAINT accounting__receipts_concession_id_fkey FOREIGN KEY (concession_id) REFERENCES public.accounting__charges(id) ON DELETE CASCADE;


--
-- Name: accounting__receipts accounting__receipts_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__receipts
    ADD CONSTRAINT accounting__receipts_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.accounting__payments(id) ON DELETE CASCADE;


--
-- Name: accounting__reconciliation_postings accounting__reconciliation_postings_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__reconciliation_postings
    ADD CONSTRAINT accounting__reconciliation_postings_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES public.accounting__bank_accounts(id);


--
-- Name: accounting__reconciliation_postings accounting__reconciliation_postings_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__reconciliation_postings
    ADD CONSTRAINT accounting__reconciliation_postings_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: accounting__reconciliations accounting__reconciliations_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__reconciliations
    ADD CONSTRAINT accounting__reconciliations_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.accounting__batches(id);


--
-- Name: accounting__reconciliations accounting__reconciliations_check_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__reconciliations
    ADD CONSTRAINT accounting__reconciliations_check_id_fkey FOREIGN KEY (check_id) REFERENCES public.accounting__checks(id);


--
-- Name: accounting__reconciliations accounting__reconciliations_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__reconciliations
    ADD CONSTRAINT accounting__reconciliations_journal_id_fkey FOREIGN KEY (journal_id) REFERENCES public.accounting__journal_entries(id);


--
-- Name: accounting__reconciliations accounting__reconciliations_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__reconciliations
    ADD CONSTRAINT accounting__reconciliations_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.accounting__payments(id);


--
-- Name: accounting__reconciliations accounting__reconciliations_posting_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__reconciliations
    ADD CONSTRAINT accounting__reconciliations_posting_id_fkey FOREIGN KEY (reconciliation_posting_id) REFERENCES public.accounting__reconciliation_postings(id);


--
-- Name: accounting__registers accounting__registers_cash_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__registers
    ADD CONSTRAINT accounting__registers_cash_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounting__accounts(id) ON DELETE CASCADE;


--
-- Name: accounting__registers accounting__registers_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__registers
    ADD CONSTRAINT accounting__registers_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: accounting__requests accounting__requests_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__requests
    ADD CONSTRAINT accounting__requests_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: accounting__requests accounting__requests_charge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__requests
    ADD CONSTRAINT accounting__requests_charge_id_fkey FOREIGN KEY (charge_id) REFERENCES public.accounting__charges(id) ON DELETE SET NULL;


--
-- Name: accounting__requests accounting__requests_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting__requests
    ADD CONSTRAINT accounting__requests_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.accounting__payments(id) ON DELETE SET NULL;


--
-- Name: accounts__accounts accounts__accounts_profile_pic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__accounts
    ADD CONSTRAINT accounts__accounts_profile_pic_id_fkey FOREIGN KEY (profile_pic_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: accounts__accounts accounts__accounts_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__accounts
    ADD CONSTRAINT accounts__accounts_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: accounts__accounts accounts__accounts_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__accounts
    ADD CONSTRAINT accounts__accounts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: accounts__autopays accounts__autopays_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__autopays
    ADD CONSTRAINT accounts__autopays_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts__accounts(id) ON DELETE CASCADE;


--
-- Name: accounts__autopays accounts__autopays_payment_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__autopays
    ADD CONSTRAINT accounts__autopays_payment_source_id_fkey FOREIGN KEY (payment_source_id) REFERENCES public.accounts__payment_sources(id) ON DELETE CASCADE;


--
-- Name: accounts__locks accounts__locks_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__locks
    ADD CONSTRAINT accounts__locks_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts__accounts(id) ON DELETE CASCADE;


--
-- Name: accounts__locks accounts__locks_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__locks
    ADD CONSTRAINT accounts__locks_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE SET NULL;


--
-- Name: accounts__logins accounts__logins_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__logins
    ADD CONSTRAINT accounts__logins_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts__accounts(id) ON DELETE CASCADE;


--
-- Name: accounts__payment_sources accounts__payment_sources_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts__payment_sources
    ADD CONSTRAINT accounts__payment_sources_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts__accounts(id) ON DELETE CASCADE;


--
-- Name: rewards__purchases accounts__purchases_prize_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__purchases
    ADD CONSTRAINT accounts__purchases_prize_id_fkey FOREIGN KEY (prize_id) REFERENCES public.rewards__prizes(id) ON DELETE CASCADE;


--
-- Name: rewards__purchases accounts__purchases_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__purchases
    ADD CONSTRAINT accounts__purchases_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: rewards__awards accounts__rewards_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__awards
    ADD CONSTRAINT accounts__rewards_account_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: rewards__awards accounts__rewards_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__awards
    ADD CONSTRAINT accounts__rewards_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.rewards__types(id) ON DELETE CASCADE;


--
-- Name: admins__actions admins__actions_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__actions
    ADD CONSTRAINT admins__actions_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: admins__alerts admins__alerts_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__alerts
    ADD CONSTRAINT admins__alerts_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: admins__alerts admins__alerts_attachment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__alerts
    ADD CONSTRAINT admins__alerts_attachment_id_fkey FOREIGN KEY (attachment_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: admins__approval_attachments admins__approval_attachments_approval_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approval_attachments
    ADD CONSTRAINT admins__approval_attachments_approval_id_fkey FOREIGN KEY (approval_id) REFERENCES public.admins__approvals(id) ON DELETE CASCADE;


--
-- Name: admins__approval_attachments admins__approval_attachments_attachment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approval_attachments
    ADD CONSTRAINT admins__approval_attachments_attachment_id_fkey FOREIGN KEY (attachment_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: admins__approval_logs admins__approval_logs_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approval_logs
    ADD CONSTRAINT admins__approval_logs_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE SET NULL;


--
-- Name: admins__approval_logs admins__approval_logs_approval_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approval_logs
    ADD CONSTRAINT admins__approval_logs_approval_id_fkey FOREIGN KEY (approval_id) REFERENCES public.admins__approvals(id) ON DELETE CASCADE;


--
-- Name: admins__approvals admins__approvals_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approvals
    ADD CONSTRAINT admins__approvals_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE SET NULL;


--
-- Name: admins__approvals_costs admins__approvals_costs_approval_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approvals_costs
    ADD CONSTRAINT admins__approvals_costs_approval_id_fkey FOREIGN KEY (approval_id) REFERENCES public.admins__approvals(id) ON DELETE CASCADE;


--
-- Name: admins__approvals_costs admins__approvals_costs_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approvals_costs
    ADD CONSTRAINT admins__approvals_costs_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.accounting__categories(id) ON DELETE CASCADE;


--
-- Name: admins__approvals_notes admins__approvals_notes_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approvals_notes
    ADD CONSTRAINT admins__approvals_notes_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: admins__approvals_notes admins__approvals_notes_approval_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approvals_notes
    ADD CONSTRAINT admins__approvals_notes_approval_id_fkey FOREIGN KEY (approval_id) REFERENCES public.admins__approvals(id) ON DELETE CASCADE;


--
-- Name: admins__approvals admins__approvals_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__approvals
    ADD CONSTRAINT admins__approvals_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: admins__device_auths admins__device_auths_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__device_auths
    ADD CONSTRAINT admins__device_auths_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.admins__devices(id) ON DELETE CASCADE;


--
-- Name: admins__device_auths admins__device_auths_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__device_auths
    ADD CONSTRAINT admins__device_auths_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: admins__messages admins__messages_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__messages
    ADD CONSTRAINT admins__messages_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: admins__org_charts admins__org_charts_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__org_charts
    ADD CONSTRAINT admins__org_charts_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id);


--
-- Name: admins__permissions admins__permissions_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__permissions
    ADD CONSTRAINT admins__permissions_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: admins__permissions admins__permissions_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__permissions
    ADD CONSTRAINT admins__permissions_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.admins__entities(id) ON DELETE CASCADE;


--
-- Name: admins__profiles admins__profiles_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__profiles
    ADD CONSTRAINT admins__profiles_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: admins__profiles admins__profiles_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins__profiles
    ADD CONSTRAINT admins__profiles_image_id_fkey FOREIGN KEY (image_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: chat__messages chat__messages_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__messages
    ADD CONSTRAINT chat__messages_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: chat__messages chat__messages_attachment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__messages
    ADD CONSTRAINT chat__messages_attachment_id_fkey FOREIGN KEY (attachment_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: chat__messages chat__messages_reply_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__messages
    ADD CONSTRAINT chat__messages_reply_id_fkey FOREIGN KEY (reply_id) REFERENCES public.chat__messages(id) ON DELETE SET NULL;


--
-- Name: chat__messages chat__messages_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__messages
    ADD CONSTRAINT chat__messages_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.chat__rooms(id) ON DELETE CASCADE;


--
-- Name: chat__read_receipts chat__read_receipts_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__read_receipts
    ADD CONSTRAINT chat__read_receipts_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: chat__read_receipts chat__read_receipts_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__read_receipts
    ADD CONSTRAINT chat__read_receipts_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.chat__messages(id) ON DELETE CASCADE;


--
-- Name: chat__read_receipts chat__read_receipts_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__read_receipts
    ADD CONSTRAINT chat__read_receipts_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.chat__rooms(id) ON DELETE CASCADE;


--
-- Name: chat__room_members chat__room_members_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__room_members
    ADD CONSTRAINT chat__room_members_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: chat__room_members chat__room_members_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__room_members
    ADD CONSTRAINT chat__room_members_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.chat__rooms(id) ON DELETE CASCADE;


--
-- Name: chat__rooms chat__rooms_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat__rooms
    ADD CONSTRAINT chat__rooms_image_id_fkey FOREIGN KEY (image_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: exports__categories exports__categories_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports__categories
    ADD CONSTRAINT exports__categories_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: exports__documents exports__documents_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports__documents
    ADD CONSTRAINT exports__documents_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.exports__categories(id) ON DELETE CASCADE;


--
-- Name: exports__documents exports__documents_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports__documents
    ADD CONSTRAINT exports__documents_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.data__uploads(id) ON DELETE CASCADE;


--
-- Name: exports__recipients exports__recipients_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports__recipients
    ADD CONSTRAINT exports__recipients_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: leases__custom_packages leases__custom_packages_lease_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__custom_packages
    ADD CONSTRAINT leases__custom_packages_lease_id_fkey FOREIGN KEY (lease_id) REFERENCES public.leases__leases(id) ON DELETE CASCADE;


--
-- Name: leases__custom_packages leases__custom_packages_renewal_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__custom_packages
    ADD CONSTRAINT leases__custom_packages_renewal_package_id_fkey FOREIGN KEY (renewal_package_id) REFERENCES public.leases__renewal_packages(id) ON DELETE CASCADE;


--
-- Name: leases__forms leases__forms_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__forms
    ADD CONSTRAINT leases__forms_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE CASCADE;


--
-- Name: leases__forms leases__forms_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__forms
    ADD CONSTRAINT leases__forms_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.data__uploads(id) ON DELETE CASCADE;


--
-- Name: leases__forms leases__forms_lease_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__forms
    ADD CONSTRAINT leases__forms_lease_id_fkey FOREIGN KEY (lease_id) REFERENCES public.leases__leases(id) ON DELETE CASCADE;


--
-- Name: leases__leases leases__leases_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__leases
    ADD CONSTRAINT leases__leases_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: leases__leases leases__leases_move_out_reason_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__leases
    ADD CONSTRAINT leases__leases_move_out_reason_id_fkey FOREIGN KEY (move_out_reason_id) REFERENCES public.settings__move_out_reasons(id);


--
-- Name: leases__leases leases__leases_renewal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__leases
    ADD CONSTRAINT leases__leases_renewal_id_fkey FOREIGN KEY (renewal_id) REFERENCES public.leases__leases(id) ON DELETE SET NULL;


--
-- Name: leases__leases leases__leases_renewal_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__leases
    ADD CONSTRAINT leases__leases_renewal_package_id_fkey FOREIGN KEY (renewal_package_id) REFERENCES public.leases__renewal_packages(id) ON DELETE CASCADE;


--
-- Name: leases__leases leases__leases_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__leases
    ADD CONSTRAINT leases__leases_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.properties__units(id) ON DELETE CASCADE;


--
-- Name: leases__renewal_packages leases__renewal_packages_renewal_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__renewal_packages
    ADD CONSTRAINT leases__renewal_packages_renewal_period_id_fkey FOREIGN KEY (renewal_period_id) REFERENCES public.leases__renewal_periods(id) ON DELETE CASCADE;


--
-- Name: leases__renewal_periods leases__renewal_periods_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__renewal_periods
    ADD CONSTRAINT leases__renewal_periods_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: leases__screenings leases__screenings_lease_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__screenings
    ADD CONSTRAINT leases__screenings_lease_id_fkey FOREIGN KEY (lease_id) REFERENCES public.leases__leases(id) ON DELETE CASCADE;


--
-- Name: leases__screenings leases__screenings_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__screenings
    ADD CONSTRAINT leases__screenings_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.rent_apply__persons(id) ON DELETE CASCADE;


--
-- Name: leases__screenings leases__screenings_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__screenings
    ADD CONSTRAINT leases__screenings_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: leases__screenings leases__screenings_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leases__screenings
    ADD CONSTRAINT leases__screenings_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: maintenance__assignments maintenance__assignments_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__assignments
    ADD CONSTRAINT maintenance__assignments_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE SET NULL;


--
-- Name: maintenance__assignments maintenance__assignments_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__assignments
    ADD CONSTRAINT maintenance__assignments_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.maintenance__orders(id) ON DELETE CASCADE;


--
-- Name: maintenance__assignments maintenance__assignments_payee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__assignments
    ADD CONSTRAINT maintenance__assignments_payee_id_fkey FOREIGN KEY (payee_id) REFERENCES public.accounting__payees(id) ON DELETE SET NULL;


--
-- Name: maintenance__assignments maintenance__assignments_tech_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__assignments
    ADD CONSTRAINT maintenance__assignments_tech_id_fkey FOREIGN KEY (tech_id) REFERENCES public.maintenance__techs(id) ON DELETE CASCADE;


--
-- Name: maintenance__card_items maintenance__card_items_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__card_items
    ADD CONSTRAINT maintenance__card_items_card_id_fkey FOREIGN KEY (card_id) REFERENCES public.maintenance__cards(id) ON DELETE CASCADE;


--
-- Name: maintenance__card_items maintenance__card_items_tech_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__card_items
    ADD CONSTRAINT maintenance__card_items_tech_id_fkey FOREIGN KEY (tech_id) REFERENCES public.maintenance__techs(id) ON DELETE SET NULL;


--
-- Name: maintenance__card_items maintenance__card_items_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__card_items
    ADD CONSTRAINT maintenance__card_items_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors__vendors(id) ON DELETE CASCADE;


--
-- Name: maintenance__cards maintenance__cards_lease_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__cards
    ADD CONSTRAINT maintenance__cards_lease_id_fkey FOREIGN KEY (lease_id) REFERENCES public.leases__leases(id) ON DELETE CASCADE;


--
-- Name: maintenance__cards maintenance__cards_occupancy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__cards
    ADD CONSTRAINT maintenance__cards_occupancy_id_fkey FOREIGN KEY (lease_id) REFERENCES public.leases__leases(id) ON DELETE CASCADE;


--
-- Name: maintenance__cards maintenance__cards_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__cards
    ADD CONSTRAINT maintenance__cards_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.properties__units(id) ON DELETE CASCADE;


--
-- Name: maintenance__categories maintenance__categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__categories
    ADD CONSTRAINT maintenance__categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.maintenance__categories(id) ON DELETE CASCADE;


--
-- Name: maintenance__timecards maintenance__clocks_tech_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__timecards
    ADD CONSTRAINT maintenance__clocks_tech_id_fkey FOREIGN KEY (tech_id) REFERENCES public.maintenance__techs(id) ON DELETE CASCADE;


--
-- Name: maintenance__inventory_logs maintenance__inventory_logs_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__inventory_logs
    ADD CONSTRAINT maintenance__inventory_logs_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials__materials(id) ON DELETE CASCADE;


--
-- Name: maintenance__jobs maintenance__jobs_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__jobs
    ADD CONSTRAINT maintenance__jobs_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: maintenance__jobs maintenance__jobs_tech_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__jobs
    ADD CONSTRAINT maintenance__jobs_tech_id_fkey FOREIGN KEY (tech_id) REFERENCES public.maintenance__techs(id) ON DELETE CASCADE;


--
-- Name: materials__logs maintenance__material_logs_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__logs
    ADD CONSTRAINT maintenance__material_logs_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials__materials(id) ON DELETE CASCADE;


--
-- Name: materials__logs maintenance__material_logs_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__logs
    ADD CONSTRAINT maintenance__material_logs_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: materials__logs maintenance__material_logs_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__logs
    ADD CONSTRAINT maintenance__material_logs_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.materials__stocks(id) ON DELETE CASCADE;


--
-- Name: materials__order_items maintenance__materials_orders_items_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__order_items
    ADD CONSTRAINT maintenance__materials_orders_items_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials__materials(id) ON DELETE CASCADE;


--
-- Name: materials__order_items maintenance__materials_orders_items_material_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__order_items
    ADD CONSTRAINT maintenance__materials_orders_items_material_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.materials__orders(id) ON DELETE CASCADE;


--
-- Name: materials__materials maintenance__materials_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__materials
    ADD CONSTRAINT maintenance__materials_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.materials__types(id) ON DELETE CASCADE;


--
-- Name: maintenance__notes maintenance__notes_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__notes
    ADD CONSTRAINT maintenance__notes_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: maintenance__notes maintenance__notes_attachment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__notes
    ADD CONSTRAINT maintenance__notes_attachment_id_fkey FOREIGN KEY (attachment_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: maintenance__notes maintenance__notes_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__notes
    ADD CONSTRAINT maintenance__notes_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.maintenance__orders(id) ON DELETE CASCADE;


--
-- Name: maintenance__notes maintenance__notes_tech_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__notes
    ADD CONSTRAINT maintenance__notes_tech_id_fkey FOREIGN KEY (tech_id) REFERENCES public.maintenance__techs(id) ON DELETE CASCADE;


--
-- Name: maintenance__notes maintenance__notes_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__notes
    ADD CONSTRAINT maintenance__notes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: maintenance__offers maintenance__offers_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__offers
    ADD CONSTRAINT maintenance__offers_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.maintenance__orders(id) ON DELETE CASCADE;


--
-- Name: maintenance__offers maintenance__offers_tech_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__offers
    ADD CONSTRAINT maintenance__offers_tech_id_fkey FOREIGN KEY (tech_id) REFERENCES public.maintenance__techs(id) ON DELETE CASCADE;


--
-- Name: maintenance__open_history maintenance__open_history_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__open_history
    ADD CONSTRAINT maintenance__open_history_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: maintenance__orders maintenance__orders_card_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__orders
    ADD CONSTRAINT maintenance__orders_card_item_id_fkey FOREIGN KEY (card_item_id) REFERENCES public.maintenance__card_items(id) ON DELETE CASCADE;


--
-- Name: maintenance__orders maintenance__orders_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__orders
    ADD CONSTRAINT maintenance__orders_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.maintenance__categories(id) ON DELETE CASCADE;


--
-- Name: maintenance__orders maintenance__orders_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__orders
    ADD CONSTRAINT maintenance__orders_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: maintenance__orders maintenance__orders_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__orders
    ADD CONSTRAINT maintenance__orders_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: maintenance__orders maintenance__orders_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__orders
    ADD CONSTRAINT maintenance__orders_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.properties__units(id) ON DELETE CASCADE;


--
-- Name: maintenance__paid_time maintenance__paid_time_tech_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__paid_time
    ADD CONSTRAINT maintenance__paid_time_tech_id_fkey FOREIGN KEY (tech_id) REFERENCES public.maintenance__techs(id) ON DELETE CASCADE;


--
-- Name: maintenance__parts maintenance__parts_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__parts
    ADD CONSTRAINT maintenance__parts_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.maintenance__orders(id) ON DELETE CASCADE;


--
-- Name: maintenance__presence_logs maintenance__presence_logs_tech_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__presence_logs
    ADD CONSTRAINT maintenance__presence_logs_tech_id_fkey FOREIGN KEY (tech_id) REFERENCES public.maintenance__techs(id) ON DELETE CASCADE;


--
-- Name: maintenance__recurring_orders maintenance__recurring_orders_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__recurring_orders
    ADD CONSTRAINT maintenance__recurring_orders_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id);


--
-- Name: maintenance__recurring_orders maintenance__recurring_orders_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__recurring_orders
    ADD CONSTRAINT maintenance__recurring_orders_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: maintenance__skills maintenance__skills_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__skills
    ADD CONSTRAINT maintenance__skills_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.maintenance__categories(id) ON DELETE CASCADE;


--
-- Name: maintenance__skills maintenance__skills_tech_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__skills
    ADD CONSTRAINT maintenance__skills_tech_id_fkey FOREIGN KEY (tech_id) REFERENCES public.maintenance__techs(id) ON DELETE CASCADE;


--
-- Name: maintenance__techs maintenance__techs_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance__techs
    ADD CONSTRAINT maintenance__techs_image_id_fkey FOREIGN KEY (image_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: materials__inventory materials__inventory_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__inventory
    ADD CONSTRAINT materials__inventory_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials__materials(id) ON DELETE CASCADE;


--
-- Name: materials__inventory materials__inventory_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__inventory
    ADD CONSTRAINT materials__inventory_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.materials__stocks(id) ON DELETE CASCADE;


--
-- Name: materials__materials materials__materials_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__materials
    ADD CONSTRAINT materials__materials_image_id_fkey FOREIGN KEY (image_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: materials__stocks materials__stocks_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__stocks
    ADD CONSTRAINT materials__stocks_image_id_fkey FOREIGN KEY (image_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: materials__stocks materials__stocks_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__stocks
    ADD CONSTRAINT materials__stocks_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.materials__warehouses(id);


--
-- Name: materials__toolbox_items materials__toolbox_items_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__toolbox_items
    ADD CONSTRAINT materials__toolbox_items_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.maintenance__assignments(id);


--
-- Name: materials__toolbox_items materials__toolbox_items_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__toolbox_items
    ADD CONSTRAINT materials__toolbox_items_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials__materials(id) ON DELETE CASCADE;


--
-- Name: materials__toolbox_items materials__toolbox_items_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__toolbox_items
    ADD CONSTRAINT materials__toolbox_items_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.materials__stocks(id) ON DELETE CASCADE;


--
-- Name: materials__toolbox_items materials__toolbox_items_tech_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__toolbox_items
    ADD CONSTRAINT materials__toolbox_items_tech_id_fkey FOREIGN KEY (tech_id) REFERENCES public.maintenance__techs(id) ON DELETE CASCADE;


--
-- Name: materials__warehouses materials__warehouses_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials__warehouses
    ADD CONSTRAINT materials__warehouses_image_id_fkey FOREIGN KEY (image_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: messaging__emails messaging__emails_body_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__emails
    ADD CONSTRAINT messaging__emails_body_id_fkey FOREIGN KEY (body_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: messaging__emails messaging__emails_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__emails
    ADD CONSTRAINT messaging__emails_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: messaging__inboxes messaging__inboxes_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__inboxes
    ADD CONSTRAINT messaging__inboxes_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: messaging__message_threads messaging__message_threads_inbox_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__message_threads
    ADD CONSTRAINT messaging__message_threads_inbox_id_fkey FOREIGN KEY (inbox_id) REFERENCES public.messaging__inboxes(id) ON DELETE CASCADE;


--
-- Name: messaging__messages messaging__messages_message_thread_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__messages
    ADD CONSTRAINT messaging__messages_message_thread_id_fkey FOREIGN KEY (message_thread_id) REFERENCES public.messaging__message_threads(id) ON DELETE CASCADE;


--
-- Name: messaging__property_templates messaging__property_templates_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__property_templates
    ADD CONSTRAINT messaging__property_templates_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: messaging__property_templates messaging__property_templates_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__property_templates
    ADD CONSTRAINT messaging__property_templates_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.messaging__mail_templates(id) ON DELETE CASCADE;


--
-- Name: messaging__routes messaging__routes_inbox_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__routes
    ADD CONSTRAINT messaging__routes_inbox_id_fkey FOREIGN KEY (inbox_id) REFERENCES public.messaging__inboxes(id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: messaging__routes messaging__routes_mail_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messaging__routes
    ADD CONSTRAINT messaging__routes_mail_address_id_fkey FOREIGN KEY (mail_address_id) REFERENCES public.messaging__mail_addresses(id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: properties__admin_documents properties__admin_documents_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__admin_documents
    ADD CONSTRAINT properties__admin_documents_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: properties__charges properties__charges_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__charges
    ADD CONSTRAINT properties__charges_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounting__accounts(id);


--
-- Name: properties__charges properties__charges_occupancy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__charges
    ADD CONSTRAINT properties__charges_occupancy_id_fkey FOREIGN KEY (lease_id) REFERENCES public.leases__leases(id) ON DELETE CASCADE;


--
-- Name: properties__documents properties__documents_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__documents
    ADD CONSTRAINT properties__documents_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: properties__documents properties__documents_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__documents
    ADD CONSTRAINT properties__documents_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: properties__evictions properties__evictions_lease_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__evictions
    ADD CONSTRAINT properties__evictions_lease_id_fkey FOREIGN KEY (lease_id) REFERENCES public.leases__leases(id) ON DELETE CASCADE;


--
-- Name: properties__features properties__features_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__features
    ADD CONSTRAINT properties__features_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: properties__floor_plan_features properties__floor_plan_features_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__floor_plan_features
    ADD CONSTRAINT properties__floor_plan_features_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES public.properties__features(id) ON DELETE CASCADE;


--
-- Name: properties__floor_plan_features properties__floor_plan_features_floor_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__floor_plan_features
    ADD CONSTRAINT properties__floor_plan_features_floor_plan_id_fkey FOREIGN KEY (floor_plan_id) REFERENCES public.properties__floor_plans(id) ON DELETE CASCADE;


--
-- Name: properties__floor_plans properties__floor_plans_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__floor_plans
    ADD CONSTRAINT properties__floor_plans_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: properties__insurances properties__insurances_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__insurances
    ADD CONSTRAINT properties__insurances_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: properties__letter_templates properties__letter_templates_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__letter_templates
    ADD CONSTRAINT properties__letter_templates_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: properties__occupancies properties__occupancies_lease_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__occupancies
    ADD CONSTRAINT properties__occupancies_lease_id_fkey FOREIGN KEY (lease_id) REFERENCES public.leases__leases(id) ON DELETE CASCADE;


--
-- Name: properties__occupancies properties__occupancies_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__occupancies
    ADD CONSTRAINT properties__occupancies_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: properties__occupants properties__occupants_lease_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__occupants
    ADD CONSTRAINT properties__occupants_lease_id_fkey FOREIGN KEY (lease_id) REFERENCES public.leases__leases(id) ON DELETE CASCADE;


--
-- Name: properties__packages properties__packages_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__packages
    ADD CONSTRAINT properties__packages_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.properties__units(id) ON DELETE CASCADE;


--
-- Name: properties__phone__lines properties__phone__lines_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__phone__lines
    ADD CONSTRAINT properties__phone__lines_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: properties__processors properties__processors_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__processors
    ADD CONSTRAINT properties__processors_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: properties__properties properties__properties_banner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__properties
    ADD CONSTRAINT properties__properties_banner_id_fkey FOREIGN KEY (banner_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: properties__properties properties__properties_icon_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__properties
    ADD CONSTRAINT properties__properties_icon_id_fkey FOREIGN KEY (icon_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: properties__properties properties__properties_logo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__properties
    ADD CONSTRAINT properties__properties_logo_id_fkey FOREIGN KEY (logo_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: properties__properties properties__properties_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__properties
    ADD CONSTRAINT properties__properties_region_id_fkey FOREIGN KEY (region_id) REFERENCES public.properties__regions(id) ON DELETE SET NULL;


--
-- Name: properties__properties properties__properties_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__properties
    ADD CONSTRAINT properties__properties_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.materials__stocks(id) ON DELETE SET NULL;


--
-- Name: properties__property_admin_documents properties__property_admin_documents_admin_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__property_admin_documents
    ADD CONSTRAINT properties__property_admin_documents_admin_document_id_fkey FOREIGN KEY (admin_document_id) REFERENCES public.properties__admin_documents(id) ON DELETE CASCADE;


--
-- Name: properties__property_admin_documents properties__property_admin_documents_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__property_admin_documents
    ADD CONSTRAINT properties__property_admin_documents_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: properties__recurring_letters properties__recurring_letters_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__recurring_letters
    ADD CONSTRAINT properties__recurring_letters_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: properties__recurring_letters properties__recurring_letters_letter_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__recurring_letters
    ADD CONSTRAINT properties__recurring_letters_letter_template_id_fkey FOREIGN KEY (letter_template_id) REFERENCES public.properties__letter_templates(id) ON DELETE CASCADE;


--
-- Name: properties__regions properties__regions_regional_supervisor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__regions
    ADD CONSTRAINT properties__regions_regional_supervisor_id_fkey FOREIGN KEY (regional_supervisor_id) REFERENCES public.admins__admins(id) ON DELETE SET NULL;


--
-- Name: properties__resident_event_attendances properties__resident_event_attendances_resident_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__resident_event_attendances
    ADD CONSTRAINT properties__resident_event_attendances_resident_event_id_fkey FOREIGN KEY (resident_event_id) REFERENCES public.properties__resident_events(id) ON DELETE CASCADE;


--
-- Name: properties__resident_event_attendances properties__resident_event_attendances_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__resident_event_attendances
    ADD CONSTRAINT properties__resident_event_attendances_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: properties__resident_events properties__resident_events_attachment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__resident_events
    ADD CONSTRAINT properties__resident_events_attachment_id_fkey FOREIGN KEY (attachment_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: properties__resident_events properties__resident_events_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__resident_events
    ADD CONSTRAINT properties__resident_events_image_id_fkey FOREIGN KEY (image_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: properties__resident_events properties__resident_events_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__resident_events
    ADD CONSTRAINT properties__resident_events_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: properties__scopings properties__scopings_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__scopings
    ADD CONSTRAINT properties__scopings_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.admins__entities(id) ON DELETE CASCADE;


--
-- Name: properties__scopings properties__scopings_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__scopings
    ADD CONSTRAINT properties__scopings_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: properties__settings properties__settings_default_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__settings
    ADD CONSTRAINT properties__settings_default_bank_account_id_fkey FOREIGN KEY (default_bank_account_id) REFERENCES public.accounting__bank_accounts(id) ON DELETE SET NULL;


--
-- Name: properties__settings properties__settings_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__settings
    ADD CONSTRAINT properties__settings_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: properties__unit_features properties__unit_features_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__unit_features
    ADD CONSTRAINT properties__unit_features_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES public.properties__features(id) ON DELETE CASCADE;


--
-- Name: properties__unit_features properties__unit_features_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__unit_features
    ADD CONSTRAINT properties__unit_features_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.properties__units(id) ON DELETE CASCADE;


--
-- Name: properties__units properties__units_floor_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__units
    ADD CONSTRAINT properties__units_floor_plan_id_fkey FOREIGN KEY (floor_plan_id) REFERENCES public.properties__floor_plans(id) ON DELETE SET NULL;


--
-- Name: properties__units properties__units_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__units
    ADD CONSTRAINT properties__units_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: properties__visits properties__visits_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__visits
    ADD CONSTRAINT properties__visits_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: properties__visits properties__visits_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties__visits
    ADD CONSTRAINT properties__visits_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: prospects__closures prospects__closures_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__closures
    ADD CONSTRAINT prospects__closures_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: prospects__memos prospects__memos_prospect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__memos
    ADD CONSTRAINT prospects__memos_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES public.prospects__prospects(id) ON DELETE CASCADE;


--
-- Name: prospects__openings prospects__openings_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__openings
    ADD CONSTRAINT prospects__openings_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: prospects__prospects prospects__prospects_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__prospects
    ADD CONSTRAINT prospects__prospects_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE SET NULL;


--
-- Name: prospects__prospects prospects__prospects_floor_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__prospects
    ADD CONSTRAINT prospects__prospects_floor_plan_id_fkey FOREIGN KEY (floor_plan_id) REFERENCES public.properties__floor_plans(id);


--
-- Name: prospects__prospects prospects__prospects_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__prospects
    ADD CONSTRAINT prospects__prospects_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: prospects__prospects prospects__prospects_traffic_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__prospects
    ADD CONSTRAINT prospects__prospects_traffic_source_id_fkey FOREIGN KEY (traffic_source_id) REFERENCES public.prospects__traffic_sources(id);


--
-- Name: prospects__showings prospects__showings_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__showings
    ADD CONSTRAINT prospects__showings_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: prospects__showings prospects__showings_prospect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__showings
    ADD CONSTRAINT prospects__showings_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES public.prospects__prospects(id) ON DELETE CASCADE;


--
-- Name: prospects__showings prospects__showings_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prospects__showings
    ADD CONSTRAINT prospects__showings_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.properties__units(id) ON DELETE CASCADE;


--
-- Name: rent_apply__documents rent_apply__documents_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__documents
    ADD CONSTRAINT rent_apply__documents_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE CASCADE;


--
-- Name: rent_apply__documents rent_apply__documents_url_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__documents
    ADD CONSTRAINT rent_apply__documents_url_id_fkey FOREIGN KEY (url_id) REFERENCES public.data__uploads(id) ON DELETE CASCADE;


--
-- Name: rent_apply__emergency_contacts rent_apply__emergency_contacts_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__emergency_contacts
    ADD CONSTRAINT rent_apply__emergency_contacts_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE CASCADE;


--
-- Name: rent_apply__employments rent_apply__employments_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__employments
    ADD CONSTRAINT rent_apply__employments_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE CASCADE;


--
-- Name: rent_apply__employments rent_apply__employments_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__employments
    ADD CONSTRAINT rent_apply__employments_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.rent_apply__persons(id) ON DELETE CASCADE;


--
-- Name: rent_apply__histories rent_apply__histories_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__histories
    ADD CONSTRAINT rent_apply__histories_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE CASCADE;


--
-- Name: rent_apply__incomes rent_apply__incomes_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__incomes
    ADD CONSTRAINT rent_apply__incomes_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE CASCADE;


--
-- Name: rent_apply__memos rent_apply__memos_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__memos
    ADD CONSTRAINT rent_apply__memos_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id);


--
-- Name: rent_apply__memos rent_apply__memos_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__memos
    ADD CONSTRAINT rent_apply__memos_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE CASCADE;


--
-- Name: rent_apply__move_ins rent_apply__move_ins_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__move_ins
    ADD CONSTRAINT rent_apply__move_ins_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE CASCADE;


--
-- Name: rent_apply__move_ins rent_apply__move_ins_floor_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__move_ins
    ADD CONSTRAINT rent_apply__move_ins_floor_plan_id_fkey FOREIGN KEY (floor_plan_id) REFERENCES public.properties__floor_plans(id) ON DELETE SET NULL;


--
-- Name: rent_apply__move_ins rent_apply__move_ins_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__move_ins
    ADD CONSTRAINT rent_apply__move_ins_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.properties__units(id) ON DELETE SET NULL;


--
-- Name: rent_apply__persons rent_apply__persons_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__persons
    ADD CONSTRAINT rent_apply__persons_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE CASCADE;


--
-- Name: rent_apply__pets rent_apply__pets_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__pets
    ADD CONSTRAINT rent_apply__pets_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE CASCADE;


--
-- Name: rent_apply__rent_applications rent_apply__rent_applications_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__rent_applications
    ADD CONSTRAINT rent_apply__rent_applications_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.admins__devices(id) ON DELETE SET NULL;


--
-- Name: rent_apply__rent_applications rent_apply__rent_applications_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__rent_applications
    ADD CONSTRAINT rent_apply__rent_applications_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: rent_apply__rent_applications rent_apply__rent_applications_prospect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__rent_applications
    ADD CONSTRAINT rent_apply__rent_applications_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES public.prospects__prospects(id) ON DELETE SET NULL;


--
-- Name: rent_apply__rent_applications rent_apply__rent_applications_security_deposit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__rent_applications
    ADD CONSTRAINT rent_apply__rent_applications_security_deposit_id_fkey FOREIGN KEY (security_deposit_id) REFERENCES public.accounting__payments(id) ON DELETE SET NULL;


--
-- Name: rent_apply__saved_forms rent_apply__saved_forms_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__saved_forms
    ADD CONSTRAINT rent_apply__saved_forms_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: rent_apply__vehicles rent_apply__vehicles_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rent_apply__vehicles
    ADD CONSTRAINT rent_apply__vehicles_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE CASCADE;


--
-- Name: rewards__prizes rewards__prizes_icon_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__prizes
    ADD CONSTRAINT rewards__prizes_icon_id_fkey FOREIGN KEY (icon_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: rewards__purchases rewards__purchases_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__purchases
    ADD CONSTRAINT rewards__purchases_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: rewards__types rewards__types_icon_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rewards__types
    ADD CONSTRAINT rewards__types_icon_id_fkey FOREIGN KEY (icon_id) REFERENCES public.data__uploads(id) ON DELETE SET NULL;


--
-- Name: settings__damages settings__damages_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings__damages
    ADD CONSTRAINT settings__damages_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounting__accounts(id) ON DELETE CASCADE;


--
-- Name: social__blocks social__blocks_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__blocks
    ADD CONSTRAINT social__blocks_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: social__posts_likes social__posts_likes_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__posts_likes
    ADD CONSTRAINT social__posts_likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.social__posts(id) ON DELETE CASCADE;


--
-- Name: social__posts_likes social__posts_likes_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__posts_likes
    ADD CONSTRAINT social__posts_likes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: social__posts social__posts_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__posts
    ADD CONSTRAINT social__posts_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: social__posts social__posts_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__posts
    ADD CONSTRAINT social__posts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: social__reports social__reports_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__reports
    ADD CONSTRAINT social__reports_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: social__reports social__reports_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__reports
    ADD CONSTRAINT social__reports_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.social__posts(id) ON DELETE CASCADE;


--
-- Name: social__reports social__reports_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social__reports
    ADD CONSTRAINT social__reports_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: tenants__pets tenants__pets_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants__pets
    ADD CONSTRAINT tenants__pets_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: tenants__tenants tenants__tenants_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants__tenants
    ADD CONSTRAINT tenants__tenants_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.rent_apply__rent_applications(id) ON DELETE SET NULL;


--
-- Name: tenants__vehicles tenants__vehicles_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants__vehicles
    ADD CONSTRAINT tenants__vehicles_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: units__default_lease_charges units__default_lease_charges_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units__default_lease_charges
    ADD CONSTRAINT units__default_lease_charges_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounting__accounts(id) ON DELETE CASCADE;


--
-- Name: units__default_lease_charges units__default_lease_charges_floor_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units__default_lease_charges
    ADD CONSTRAINT units__default_lease_charges_floor_plan_id_fkey FOREIGN KEY (floor_plan_id) REFERENCES public.properties__floor_plans(id) ON DELETE CASCADE;


--
-- Name: vendor__properties vendor__properties_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor__properties
    ADD CONSTRAINT vendor__properties_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: vendor__properties vendor__properties_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor__properties
    ADD CONSTRAINT vendor__properties_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors__vendors(id) ON DELETE CASCADE;


--
-- Name: vendors__notes vendors__notes_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__notes
    ADD CONSTRAINT vendors__notes_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: vendors__notes vendors__notes_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__notes
    ADD CONSTRAINT vendors__notes_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.vendors__orders(id) ON DELETE CASCADE;


--
-- Name: vendors__notes vendors__notes_tech_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__notes
    ADD CONSTRAINT vendors__notes_tech_id_fkey FOREIGN KEY (tech_id) REFERENCES public.maintenance__techs(id) ON DELETE CASCADE;


--
-- Name: vendors__notes vendors__notes_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__notes
    ADD CONSTRAINT vendors__notes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: vendors__notes vendors__notes_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__notes
    ADD CONSTRAINT vendors__notes_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors__vendors(id) ON DELETE CASCADE;


--
-- Name: vendors__orders vendors__orders_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__orders
    ADD CONSTRAINT vendors__orders_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins__admins(id) ON DELETE CASCADE;


--
-- Name: vendors__orders vendors__orders_card_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__orders
    ADD CONSTRAINT vendors__orders_card_item_id_fkey FOREIGN KEY (card_item_id) REFERENCES public.maintenance__card_items(id) ON DELETE CASCADE;


--
-- Name: vendors__orders vendors__orders_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__orders
    ADD CONSTRAINT vendors__orders_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.vendors__categories(id) ON DELETE CASCADE;


--
-- Name: vendors__orders vendors__orders_property_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__orders
    ADD CONSTRAINT vendors__orders_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties__properties(id) ON DELETE CASCADE;


--
-- Name: vendors__orders vendors__orders_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__orders
    ADD CONSTRAINT vendors__orders_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants__tenants(id) ON DELETE CASCADE;


--
-- Name: vendors__orders vendors__orders_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__orders
    ADD CONSTRAINT vendors__orders_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.properties__units(id) ON DELETE CASCADE;


--
-- Name: vendors__orders vendors__orders_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors__orders
    ADD CONSTRAINT vendors__orders_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors__vendors(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20170328041508);
INSERT INTO public."schema_migrations" (version) VALUES (20170328041515);
INSERT INTO public."schema_migrations" (version) VALUES (20170403160158);
INSERT INTO public."schema_migrations" (version) VALUES (20170416024623);
INSERT INTO public."schema_migrations" (version) VALUES (20170416024634);
INSERT INTO public."schema_migrations" (version) VALUES (20170416024658);
INSERT INTO public."schema_migrations" (version) VALUES (20170416024705);
INSERT INTO public."schema_migrations" (version) VALUES (20170416024935);
INSERT INTO public."schema_migrations" (version) VALUES (20170416080412);
INSERT INTO public."schema_migrations" (version) VALUES (20170423182151);
INSERT INTO public."schema_migrations" (version) VALUES (20170426043238);
INSERT INTO public."schema_migrations" (version) VALUES (20170426064341);
INSERT INTO public."schema_migrations" (version) VALUES (20170428122713);
INSERT INTO public."schema_migrations" (version) VALUES (20170430165750);
INSERT INTO public."schema_migrations" (version) VALUES (20170505093018);
INSERT INTO public."schema_migrations" (version) VALUES (20170512121428);
INSERT INTO public."schema_migrations" (version) VALUES (20170924173230);
INSERT INTO public."schema_migrations" (version) VALUES (20170925173131);
INSERT INTO public."schema_migrations" (version) VALUES (20170928065940);
INSERT INTO public."schema_migrations" (version) VALUES (20170928070943);
INSERT INTO public."schema_migrations" (version) VALUES (20170928071135);
INSERT INTO public."schema_migrations" (version) VALUES (20170928081241);
INSERT INTO public."schema_migrations" (version) VALUES (20170928081504);
INSERT INTO public."schema_migrations" (version) VALUES (20170928081756);
INSERT INTO public."schema_migrations" (version) VALUES (20170928084611);
INSERT INTO public."schema_migrations" (version) VALUES (20171020111343);
INSERT INTO public."schema_migrations" (version) VALUES (20171204103711);
INSERT INTO public."schema_migrations" (version) VALUES (20171204173602);
INSERT INTO public."schema_migrations" (version) VALUES (20171205030504);
INSERT INTO public."schema_migrations" (version) VALUES (20171205032331);
INSERT INTO public."schema_migrations" (version) VALUES (20171205160931);
INSERT INTO public."schema_migrations" (version) VALUES (20171207112438);
INSERT INTO public."schema_migrations" (version) VALUES (20171217122324);
INSERT INTO public."schema_migrations" (version) VALUES (20171220034647);
INSERT INTO public."schema_migrations" (version) VALUES (20171220035037);
INSERT INTO public."schema_migrations" (version) VALUES (20171220035405);
INSERT INTO public."schema_migrations" (version) VALUES (20171220091133);
INSERT INTO public."schema_migrations" (version) VALUES (20171226035137);
INSERT INTO public."schema_migrations" (version) VALUES (20171226065626);
INSERT INTO public."schema_migrations" (version) VALUES (20171226113002);
INSERT INTO public."schema_migrations" (version) VALUES (20171226114144);
INSERT INTO public."schema_migrations" (version) VALUES (20171226123339);
INSERT INTO public."schema_migrations" (version) VALUES (20171226141528);
INSERT INTO public."schema_migrations" (version) VALUES (20171226173720);
INSERT INTO public."schema_migrations" (version) VALUES (20180101095755);
INSERT INTO public."schema_migrations" (version) VALUES (20180101100946);
INSERT INTO public."schema_migrations" (version) VALUES (20180101101330);
INSERT INTO public."schema_migrations" (version) VALUES (20180110155446);
INSERT INTO public."schema_migrations" (version) VALUES (20180111082730);
INSERT INTO public."schema_migrations" (version) VALUES (20180111183738);
INSERT INTO public."schema_migrations" (version) VALUES (20180114190729);
INSERT INTO public."schema_migrations" (version) VALUES (20180114191150);
INSERT INTO public."schema_migrations" (version) VALUES (20180115165056);
INSERT INTO public."schema_migrations" (version) VALUES (20180118094301);
INSERT INTO public."schema_migrations" (version) VALUES (20180118131741);
INSERT INTO public."schema_migrations" (version) VALUES (20180122083044);
INSERT INTO public."schema_migrations" (version) VALUES (20180123093521);
INSERT INTO public."schema_migrations" (version) VALUES (20180125045209);
INSERT INTO public."schema_migrations" (version) VALUES (20180125070156);
INSERT INTO public."schema_migrations" (version) VALUES (20180125070237);
INSERT INTO public."schema_migrations" (version) VALUES (20180125070252);
INSERT INTO public."schema_migrations" (version) VALUES (20180125071550);
INSERT INTO public."schema_migrations" (version) VALUES (20180125071619);
INSERT INTO public."schema_migrations" (version) VALUES (20180125071954);
INSERT INTO public."schema_migrations" (version) VALUES (20180128073118);
INSERT INTO public."schema_migrations" (version) VALUES (20180128100410);
INSERT INTO public."schema_migrations" (version) VALUES (20180128161612);
INSERT INTO public."schema_migrations" (version) VALUES (20180130050152);
INSERT INTO public."schema_migrations" (version) VALUES (20180130204331);
INSERT INTO public."schema_migrations" (version) VALUES (20180131173107);
INSERT INTO public."schema_migrations" (version) VALUES (20180204045800);
INSERT INTO public."schema_migrations" (version) VALUES (20180205154450);
INSERT INTO public."schema_migrations" (version) VALUES (20180208071915);
INSERT INTO public."schema_migrations" (version) VALUES (20180208174936);
INSERT INTO public."schema_migrations" (version) VALUES (20180209104258);
INSERT INTO public."schema_migrations" (version) VALUES (20180210173836);
INSERT INTO public."schema_migrations" (version) VALUES (20180211085250);
INSERT INTO public."schema_migrations" (version) VALUES (20180214060313);
INSERT INTO public."schema_migrations" (version) VALUES (20180218085326);
INSERT INTO public."schema_migrations" (version) VALUES (20180223113257);
INSERT INTO public."schema_migrations" (version) VALUES (20180227164030);
INSERT INTO public."schema_migrations" (version) VALUES (20180227164319);
INSERT INTO public."schema_migrations" (version) VALUES (20180304075315);
INSERT INTO public."schema_migrations" (version) VALUES (20180306082719);
INSERT INTO public."schema_migrations" (version) VALUES (20180306095208);
INSERT INTO public."schema_migrations" (version) VALUES (20180319165949);
INSERT INTO public."schema_migrations" (version) VALUES (20180321141603);
INSERT INTO public."schema_migrations" (version) VALUES (20180411143205);
INSERT INTO public."schema_migrations" (version) VALUES (20180411165606);
INSERT INTO public."schema_migrations" (version) VALUES (20180412064746);
INSERT INTO public."schema_migrations" (version) VALUES (20180412135638);
INSERT INTO public."schema_migrations" (version) VALUES (20180415114522);
INSERT INTO public."schema_migrations" (version) VALUES (20180415124127);
INSERT INTO public."schema_migrations" (version) VALUES (20180415144507);
INSERT INTO public."schema_migrations" (version) VALUES (20180416092621);
INSERT INTO public."schema_migrations" (version) VALUES (20180416113822);
INSERT INTO public."schema_migrations" (version) VALUES (20180418055758);
INSERT INTO public."schema_migrations" (version) VALUES (20180418171744);
INSERT INTO public."schema_migrations" (version) VALUES (20180419074201);
INSERT INTO public."schema_migrations" (version) VALUES (20180423085502);
INSERT INTO public."schema_migrations" (version) VALUES (20180424050633);
INSERT INTO public."schema_migrations" (version) VALUES (20180424053145);
INSERT INTO public."schema_migrations" (version) VALUES (20180424053325);
INSERT INTO public."schema_migrations" (version) VALUES (20180424134259);
INSERT INTO public."schema_migrations" (version) VALUES (20180425173427);
INSERT INTO public."schema_migrations" (version) VALUES (20180425173640);
INSERT INTO public."schema_migrations" (version) VALUES (20180426165058);
INSERT INTO public."schema_migrations" (version) VALUES (20180426172302);
INSERT INTO public."schema_migrations" (version) VALUES (20180427031237);
INSERT INTO public."schema_migrations" (version) VALUES (20180429143241);
INSERT INTO public."schema_migrations" (version) VALUES (20180429174133);
INSERT INTO public."schema_migrations" (version) VALUES (20180501091817);
INSERT INTO public."schema_migrations" (version) VALUES (20180502085255);
INSERT INTO public."schema_migrations" (version) VALUES (20180502105708);
INSERT INTO public."schema_migrations" (version) VALUES (20180502110842);
INSERT INTO public."schema_migrations" (version) VALUES (20180504073135);
INSERT INTO public."schema_migrations" (version) VALUES (20180507115107);
INSERT INTO public."schema_migrations" (version) VALUES (20180508070639);
INSERT INTO public."schema_migrations" (version) VALUES (20180508082722);
INSERT INTO public."schema_migrations" (version) VALUES (20180508085547);
INSERT INTO public."schema_migrations" (version) VALUES (20180510082242);
INSERT INTO public."schema_migrations" (version) VALUES (20180510130157);
INSERT INTO public."schema_migrations" (version) VALUES (20180513042433);
INSERT INTO public."schema_migrations" (version) VALUES (20180514044456);
INSERT INTO public."schema_migrations" (version) VALUES (20180516073303);
INSERT INTO public."schema_migrations" (version) VALUES (20180516104617);
INSERT INTO public."schema_migrations" (version) VALUES (20180517151021);
INSERT INTO public."schema_migrations" (version) VALUES (20180522114241);
INSERT INTO public."schema_migrations" (version) VALUES (20180523101019);
INSERT INTO public."schema_migrations" (version) VALUES (20180527055607);
INSERT INTO public."schema_migrations" (version) VALUES (20180528074354);
INSERT INTO public."schema_migrations" (version) VALUES (20180529151615);
INSERT INTO public."schema_migrations" (version) VALUES (20180530055525);
INSERT INTO public."schema_migrations" (version) VALUES (20180530080317);
INSERT INTO public."schema_migrations" (version) VALUES (20180530110636);
INSERT INTO public."schema_migrations" (version) VALUES (20180530145006);
INSERT INTO public."schema_migrations" (version) VALUES (20180530155113);
INSERT INTO public."schema_migrations" (version) VALUES (20180612060128);
INSERT INTO public."schema_migrations" (version) VALUES (20180612084341);
INSERT INTO public."schema_migrations" (version) VALUES (20180612101757);
INSERT INTO public."schema_migrations" (version) VALUES (20180613065148);
INSERT INTO public."schema_migrations" (version) VALUES (20180614064824);
INSERT INTO public."schema_migrations" (version) VALUES (20180614113849);
INSERT INTO public."schema_migrations" (version) VALUES (20180615093918);
INSERT INTO public."schema_migrations" (version) VALUES (20180620141658);
INSERT INTO public."schema_migrations" (version) VALUES (20180621144905);
INSERT INTO public."schema_migrations" (version) VALUES (20180621145333);
INSERT INTO public."schema_migrations" (version) VALUES (20180621202546);
INSERT INTO public."schema_migrations" (version) VALUES (20180624065433);
INSERT INTO public."schema_migrations" (version) VALUES (20180624070834);
INSERT INTO public."schema_migrations" (version) VALUES (20180624071237);
INSERT INTO public."schema_migrations" (version) VALUES (20180625113504);
INSERT INTO public."schema_migrations" (version) VALUES (20180625153532);
INSERT INTO public."schema_migrations" (version) VALUES (20180626154541);
INSERT INTO public."schema_migrations" (version) VALUES (20180702001203);
INSERT INTO public."schema_migrations" (version) VALUES (20180704175449);
INSERT INTO public."schema_migrations" (version) VALUES (20180706050045);
INSERT INTO public."schema_migrations" (version) VALUES (20180706092717);
INSERT INTO public."schema_migrations" (version) VALUES (20180708164046);
INSERT INTO public."schema_migrations" (version) VALUES (20180709133930);
INSERT INTO public."schema_migrations" (version) VALUES (20180709165101);
INSERT INTO public."schema_migrations" (version) VALUES (20180710073318);
INSERT INTO public."schema_migrations" (version) VALUES (20180712051356);
INSERT INTO public."schema_migrations" (version) VALUES (20180712052655);
INSERT INTO public."schema_migrations" (version) VALUES (20180712053242);
INSERT INTO public."schema_migrations" (version) VALUES (20180712124704);
INSERT INTO public."schema_migrations" (version) VALUES (20180712134409);
INSERT INTO public."schema_migrations" (version) VALUES (20180712160917);
INSERT INTO public."schema_migrations" (version) VALUES (20180713024232);
INSERT INTO public."schema_migrations" (version) VALUES (20180713071654);
INSERT INTO public."schema_migrations" (version) VALUES (20180713114226);
INSERT INTO public."schema_migrations" (version) VALUES (20180713175457);
INSERT INTO public."schema_migrations" (version) VALUES (20180715051919);
INSERT INTO public."schema_migrations" (version) VALUES (20180715113713);
INSERT INTO public."schema_migrations" (version) VALUES (20180716015038);
INSERT INTO public."schema_migrations" (version) VALUES (20180716020454);
INSERT INTO public."schema_migrations" (version) VALUES (20180717102101);
INSERT INTO public."schema_migrations" (version) VALUES (20180717112640);
INSERT INTO public."schema_migrations" (version) VALUES (20180717132019);
INSERT INTO public."schema_migrations" (version) VALUES (20180717132859);
INSERT INTO public."schema_migrations" (version) VALUES (20180717133459);
INSERT INTO public."schema_migrations" (version) VALUES (20180717134236);
INSERT INTO public."schema_migrations" (version) VALUES (20180719160025);
INSERT INTO public."schema_migrations" (version) VALUES (20180719173407);
INSERT INTO public."schema_migrations" (version) VALUES (20180719180659);
INSERT INTO public."schema_migrations" (version) VALUES (20180720135130);
INSERT INTO public."schema_migrations" (version) VALUES (20180723134331);
INSERT INTO public."schema_migrations" (version) VALUES (20180726015905);
INSERT INTO public."schema_migrations" (version) VALUES (20180726054230);
INSERT INTO public."schema_migrations" (version) VALUES (20180726165502);
INSERT INTO public."schema_migrations" (version) VALUES (20180729164835);
INSERT INTO public."schema_migrations" (version) VALUES (20180731080609);
INSERT INTO public."schema_migrations" (version) VALUES (20180731094212);
INSERT INTO public."schema_migrations" (version) VALUES (20180801035836);
INSERT INTO public."schema_migrations" (version) VALUES (20180802063001);
INSERT INTO public."schema_migrations" (version) VALUES (20180802081054);
INSERT INTO public."schema_migrations" (version) VALUES (20180802123646);
INSERT INTO public."schema_migrations" (version) VALUES (20180808150506);
INSERT INTO public."schema_migrations" (version) VALUES (20180809074644);
INSERT INTO public."schema_migrations" (version) VALUES (20180809193023);
INSERT INTO public."schema_migrations" (version) VALUES (20180810042849);
INSERT INTO public."schema_migrations" (version) VALUES (20180810151806);
INSERT INTO public."schema_migrations" (version) VALUES (20180811193145);
INSERT INTO public."schema_migrations" (version) VALUES (20180813120514);
INSERT INTO public."schema_migrations" (version) VALUES (20180814141923);
INSERT INTO public."schema_migrations" (version) VALUES (20180816140431);
INSERT INTO public."schema_migrations" (version) VALUES (20180816165358);
INSERT INTO public."schema_migrations" (version) VALUES (20180817153316);
INSERT INTO public."schema_migrations" (version) VALUES (20180818180816);
INSERT INTO public."schema_migrations" (version) VALUES (20180818183656);
INSERT INTO public."schema_migrations" (version) VALUES (20180820121357);
INSERT INTO public."schema_migrations" (version) VALUES (20180822043504);
INSERT INTO public."schema_migrations" (version) VALUES (20180823174400);
INSERT INTO public."schema_migrations" (version) VALUES (20180824063148);
INSERT INTO public."schema_migrations" (version) VALUES (20180826144957);
INSERT INTO public."schema_migrations" (version) VALUES (20180827162217);
INSERT INTO public."schema_migrations" (version) VALUES (20180828061550);
INSERT INTO public."schema_migrations" (version) VALUES (20180828141923);
INSERT INTO public."schema_migrations" (version) VALUES (20180828142844);
INSERT INTO public."schema_migrations" (version) VALUES (20180828174001);
INSERT INTO public."schema_migrations" (version) VALUES (20180829181528);
INSERT INTO public."schema_migrations" (version) VALUES (20180829181850);
INSERT INTO public."schema_migrations" (version) VALUES (20180829211151);
INSERT INTO public."schema_migrations" (version) VALUES (20180830133212);
INSERT INTO public."schema_migrations" (version) VALUES (20180830181852);
INSERT INTO public."schema_migrations" (version) VALUES (20180903143244);
INSERT INTO public."schema_migrations" (version) VALUES (20180903172253);
INSERT INTO public."schema_migrations" (version) VALUES (20180905144318);
INSERT INTO public."schema_migrations" (version) VALUES (20180906113456);
INSERT INTO public."schema_migrations" (version) VALUES (20180906140503);
INSERT INTO public."schema_migrations" (version) VALUES (20180913171634);
INSERT INTO public."schema_migrations" (version) VALUES (20180914081427);
INSERT INTO public."schema_migrations" (version) VALUES (20180914171343);
INSERT INTO public."schema_migrations" (version) VALUES (20180916114607);
INSERT INTO public."schema_migrations" (version) VALUES (20180918154907);
INSERT INTO public."schema_migrations" (version) VALUES (20180920145433);
INSERT INTO public."schema_migrations" (version) VALUES (20180921180125);
INSERT INTO public."schema_migrations" (version) VALUES (20180925133532);
INSERT INTO public."schema_migrations" (version) VALUES (20180926080714);
INSERT INTO public."schema_migrations" (version) VALUES (20181002140840);
INSERT INTO public."schema_migrations" (version) VALUES (20181008160155);
INSERT INTO public."schema_migrations" (version) VALUES (20181008163331);
INSERT INTO public."schema_migrations" (version) VALUES (20181011145200);
INSERT INTO public."schema_migrations" (version) VALUES (20181011152712);
INSERT INTO public."schema_migrations" (version) VALUES (20181012143310);
INSERT INTO public."schema_migrations" (version) VALUES (20181016104630);
INSERT INTO public."schema_migrations" (version) VALUES (20181017195038);
INSERT INTO public."schema_migrations" (version) VALUES (20181017195118);
INSERT INTO public."schema_migrations" (version) VALUES (20181018134019);
INSERT INTO public."schema_migrations" (version) VALUES (20181025105219);
INSERT INTO public."schema_migrations" (version) VALUES (20181025110508);
INSERT INTO public."schema_migrations" (version) VALUES (20181025111123);
INSERT INTO public."schema_migrations" (version) VALUES (20181025111957);
INSERT INTO public."schema_migrations" (version) VALUES (20181025124851);
INSERT INTO public."schema_migrations" (version) VALUES (20181025204515);
INSERT INTO public."schema_migrations" (version) VALUES (20181026001924);
INSERT INTO public."schema_migrations" (version) VALUES (20181028080441);
INSERT INTO public."schema_migrations" (version) VALUES (20181030161354);
INSERT INTO public."schema_migrations" (version) VALUES (20181031170127);
INSERT INTO public."schema_migrations" (version) VALUES (20181101155207);
INSERT INTO public."schema_migrations" (version) VALUES (20181105174257);
INSERT INTO public."schema_migrations" (version) VALUES (20181107173913);
INSERT INTO public."schema_migrations" (version) VALUES (20181107181542);
INSERT INTO public."schema_migrations" (version) VALUES (20181107190444);
INSERT INTO public."schema_migrations" (version) VALUES (20181108215702);
INSERT INTO public."schema_migrations" (version) VALUES (20181108221539);
INSERT INTO public."schema_migrations" (version) VALUES (20181111151026);
INSERT INTO public."schema_migrations" (version) VALUES (20181112135327);
INSERT INTO public."schema_migrations" (version) VALUES (20181119072317);
INSERT INTO public."schema_migrations" (version) VALUES (20181125103505);
INSERT INTO public."schema_migrations" (version) VALUES (20181126140722);
INSERT INTO public."schema_migrations" (version) VALUES (20181126141404);
INSERT INTO public."schema_migrations" (version) VALUES (20181126183143);
INSERT INTO public."schema_migrations" (version) VALUES (20181127170350);
INSERT INTO public."schema_migrations" (version) VALUES (20181127171113);
INSERT INTO public."schema_migrations" (version) VALUES (20181128074717);
INSERT INTO public."schema_migrations" (version) VALUES (20181128133349);
INSERT INTO public."schema_migrations" (version) VALUES (20181128145022);
INSERT INTO public."schema_migrations" (version) VALUES (20181202060631);
INSERT INTO public."schema_migrations" (version) VALUES (20181202061020);
INSERT INTO public."schema_migrations" (version) VALUES (20181203175517);
INSERT INTO public."schema_migrations" (version) VALUES (20181203222513);
INSERT INTO public."schema_migrations" (version) VALUES (20181205083849);
INSERT INTO public."schema_migrations" (version) VALUES (20181205105505);
INSERT INTO public."schema_migrations" (version) VALUES (20181205141513);
INSERT INTO public."schema_migrations" (version) VALUES (20181205160343);
INSERT INTO public."schema_migrations" (version) VALUES (20181205190643);
INSERT INTO public."schema_migrations" (version) VALUES (20181206095730);
INSERT INTO public."schema_migrations" (version) VALUES (20181206145539);
INSERT INTO public."schema_migrations" (version) VALUES (20181206222955);
INSERT INTO public."schema_migrations" (version) VALUES (20181209125013);
INSERT INTO public."schema_migrations" (version) VALUES (20181210082421);
INSERT INTO public."schema_migrations" (version) VALUES (20181212164127);
INSERT INTO public."schema_migrations" (version) VALUES (20181213104549);
INSERT INTO public."schema_migrations" (version) VALUES (20181213173311);
INSERT INTO public."schema_migrations" (version) VALUES (20181214155600);
INSERT INTO public."schema_migrations" (version) VALUES (20181216144913);
INSERT INTO public."schema_migrations" (version) VALUES (20181217210408);
INSERT INTO public."schema_migrations" (version) VALUES (20181218075522);
INSERT INTO public."schema_migrations" (version) VALUES (20181219210007);
INSERT INTO public."schema_migrations" (version) VALUES (20181222194736);
INSERT INTO public."schema_migrations" (version) VALUES (20181223082709);
INSERT INTO public."schema_migrations" (version) VALUES (20181224155729);
INSERT INTO public."schema_migrations" (version) VALUES (20181226152559);
INSERT INTO public."schema_migrations" (version) VALUES (20181226172243);
INSERT INTO public."schema_migrations" (version) VALUES (20181227213551);
INSERT INTO public."schema_migrations" (version) VALUES (20190102194911);
INSERT INTO public."schema_migrations" (version) VALUES (20190107154011);
INSERT INTO public."schema_migrations" (version) VALUES (20190108162355);
INSERT INTO public."schema_migrations" (version) VALUES (20190108172814);
INSERT INTO public."schema_migrations" (version) VALUES (20190109032446);
INSERT INTO public."schema_migrations" (version) VALUES (20190111135440);
INSERT INTO public."schema_migrations" (version) VALUES (20190111155348);
INSERT INTO public."schema_migrations" (version) VALUES (20190113121154);
INSERT INTO public."schema_migrations" (version) VALUES (20190114195248);
INSERT INTO public."schema_migrations" (version) VALUES (20190116085458);
INSERT INTO public."schema_migrations" (version) VALUES (20190116210429);
INSERT INTO public."schema_migrations" (version) VALUES (20190120074605);
INSERT INTO public."schema_migrations" (version) VALUES (20190122092518);
INSERT INTO public."schema_migrations" (version) VALUES (20190128200806);
INSERT INTO public."schema_migrations" (version) VALUES (20190129201905);
INSERT INTO public."schema_migrations" (version) VALUES (20190205213606);
INSERT INTO public."schema_migrations" (version) VALUES (20190207180744);
INSERT INTO public."schema_migrations" (version) VALUES (20190211175521);
INSERT INTO public."schema_migrations" (version) VALUES (20190219191707);
INSERT INTO public."schema_migrations" (version) VALUES (20190221183213);
INSERT INTO public."schema_migrations" (version) VALUES (20190226055444);
INSERT INTO public."schema_migrations" (version) VALUES (20190228043854);
INSERT INTO public."schema_migrations" (version) VALUES (20190228170442);
INSERT INTO public."schema_migrations" (version) VALUES (20190304083937);
INSERT INTO public."schema_migrations" (version) VALUES (20190304111858);
INSERT INTO public."schema_migrations" (version) VALUES (20190306203911);
INSERT INTO public."schema_migrations" (version) VALUES (20190307210659);
INSERT INTO public."schema_migrations" (version) VALUES (20190308151924);
INSERT INTO public."schema_migrations" (version) VALUES (20190308155645);
INSERT INTO public."schema_migrations" (version) VALUES (20190310094454);
INSERT INTO public."schema_migrations" (version) VALUES (20190311040451);
INSERT INTO public."schema_migrations" (version) VALUES (20190311105304);
INSERT INTO public."schema_migrations" (version) VALUES (20190312033657);
INSERT INTO public."schema_migrations" (version) VALUES (20190312152149);
INSERT INTO public."schema_migrations" (version) VALUES (20190320102242);
INSERT INTO public."schema_migrations" (version) VALUES (20190327043042);
INSERT INTO public."schema_migrations" (version) VALUES (20190327115602);
INSERT INTO public."schema_migrations" (version) VALUES (20190327155216);
INSERT INTO public."schema_migrations" (version) VALUES (20190331151020);
INSERT INTO public."schema_migrations" (version) VALUES (20190403042819);
INSERT INTO public."schema_migrations" (version) VALUES (20190403175710);
INSERT INTO public."schema_migrations" (version) VALUES (20190404191034);
INSERT INTO public."schema_migrations" (version) VALUES (20190405153954);
INSERT INTO public."schema_migrations" (version) VALUES (20190405155201);
INSERT INTO public."schema_migrations" (version) VALUES (20190405170149);
INSERT INTO public."schema_migrations" (version) VALUES (20190406180536);
INSERT INTO public."schema_migrations" (version) VALUES (20190408051743);
INSERT INTO public."schema_migrations" (version) VALUES (20190418072651);
INSERT INTO public."schema_migrations" (version) VALUES (20190418072906);
INSERT INTO public."schema_migrations" (version) VALUES (20190418073030);
INSERT INTO public."schema_migrations" (version) VALUES (20190418133008);
INSERT INTO public."schema_migrations" (version) VALUES (20190424003329);
INSERT INTO public."schema_migrations" (version) VALUES (20190424082950);
INSERT INTO public."schema_migrations" (version) VALUES (20190428144043);
INSERT INTO public."schema_migrations" (version) VALUES (20190430064632);
INSERT INTO public."schema_migrations" (version) VALUES (20190430073001);
INSERT INTO public."schema_migrations" (version) VALUES (20190501101754);
INSERT INTO public."schema_migrations" (version) VALUES (20190501173218);
INSERT INTO public."schema_migrations" (version) VALUES (20190502131720);
INSERT INTO public."schema_migrations" (version) VALUES (20190503025948);
INSERT INTO public."schema_migrations" (version) VALUES (20190503095453);
INSERT INTO public."schema_migrations" (version) VALUES (20190503122616);
INSERT INTO public."schema_migrations" (version) VALUES (20190503150525);
INSERT INTO public."schema_migrations" (version) VALUES (20190505144031);
INSERT INTO public."schema_migrations" (version) VALUES (20190505172416);
INSERT INTO public."schema_migrations" (version) VALUES (20190506034002);
INSERT INTO public."schema_migrations" (version) VALUES (20190506100157);
INSERT INTO public."schema_migrations" (version) VALUES (20190507093354);
INSERT INTO public."schema_migrations" (version) VALUES (20190509115452);
INSERT INTO public."schema_migrations" (version) VALUES (20190510095823);
INSERT INTO public."schema_migrations" (version) VALUES (20190513094233);
INSERT INTO public."schema_migrations" (version) VALUES (20190514125757);
INSERT INTO public."schema_migrations" (version) VALUES (20190514191432);
INSERT INTO public."schema_migrations" (version) VALUES (20190514210146);
INSERT INTO public."schema_migrations" (version) VALUES (20190519091441);
INSERT INTO public."schema_migrations" (version) VALUES (20190519092743);
INSERT INTO public."schema_migrations" (version) VALUES (20190520094001);
INSERT INTO public."schema_migrations" (version) VALUES (20190521082247);
INSERT INTO public."schema_migrations" (version) VALUES (20190522121914);
INSERT INTO public."schema_migrations" (version) VALUES (20190522164257);
INSERT INTO public."schema_migrations" (version) VALUES (20190522165222);
INSERT INTO public."schema_migrations" (version) VALUES (20190523132730);
INSERT INTO public."schema_migrations" (version) VALUES (20190524114151);
INSERT INTO public."schema_migrations" (version) VALUES (20190526060757);
INSERT INTO public."schema_migrations" (version) VALUES (20190530120423);
INSERT INTO public."schema_migrations" (version) VALUES (20190531112908);
INSERT INTO public."schema_migrations" (version) VALUES (20190531180344);
INSERT INTO public."schema_migrations" (version) VALUES (20190603161840);
INSERT INTO public."schema_migrations" (version) VALUES (20190603165937);
INSERT INTO public."schema_migrations" (version) VALUES (20190605055858);
INSERT INTO public."schema_migrations" (version) VALUES (20190605122418);
INSERT INTO public."schema_migrations" (version) VALUES (20190605195054);
INSERT INTO public."schema_migrations" (version) VALUES (20190606023558);
INSERT INTO public."schema_migrations" (version) VALUES (20190606102132);
INSERT INTO public."schema_migrations" (version) VALUES (20190609190800);
INSERT INTO public."schema_migrations" (version) VALUES (20190612084640);
INSERT INTO public."schema_migrations" (version) VALUES (20190613203043);
INSERT INTO public."schema_migrations" (version) VALUES (20190617090705);
INSERT INTO public."schema_migrations" (version) VALUES (20190617135256);
INSERT INTO public."schema_migrations" (version) VALUES (20190618060905);
INSERT INTO public."schema_migrations" (version) VALUES (20190619155402);
INSERT INTO public."schema_migrations" (version) VALUES (20190619165931);
INSERT INTO public."schema_migrations" (version) VALUES (20190619193953);
INSERT INTO public."schema_migrations" (version) VALUES (20190620063432);
INSERT INTO public."schema_migrations" (version) VALUES (20190620135518);
INSERT INTO public."schema_migrations" (version) VALUES (20190623171603);
INSERT INTO public."schema_migrations" (version) VALUES (20190624133300);
INSERT INTO public."schema_migrations" (version) VALUES (20190624175000);
INSERT INTO public."schema_migrations" (version) VALUES (20190625221748);
INSERT INTO public."schema_migrations" (version) VALUES (20190625231853);
INSERT INTO public."schema_migrations" (version) VALUES (20190626150332);
INSERT INTO public."schema_migrations" (version) VALUES (20190626184643);
INSERT INTO public."schema_migrations" (version) VALUES (20190628130423);
INSERT INTO public."schema_migrations" (version) VALUES (20190630034859);
INSERT INTO public."schema_migrations" (version) VALUES (20190630091225);
INSERT INTO public."schema_migrations" (version) VALUES (20190701160106);
INSERT INTO public."schema_migrations" (version) VALUES (20190711125049);
INSERT INTO public."schema_migrations" (version) VALUES (20190711161743);
INSERT INTO public."schema_migrations" (version) VALUES (20190711162832);
INSERT INTO public."schema_migrations" (version) VALUES (20190711171850);
INSERT INTO public."schema_migrations" (version) VALUES (20190712125235);
INSERT INTO public."schema_migrations" (version) VALUES (20190714031426);
INSERT INTO public."schema_migrations" (version) VALUES (20190714135020);
INSERT INTO public."schema_migrations" (version) VALUES (20190714144914);
INSERT INTO public."schema_migrations" (version) VALUES (20190714154000);
INSERT INTO public."schema_migrations" (version) VALUES (20190715141418);
INSERT INTO public."schema_migrations" (version) VALUES (20190715172458);
INSERT INTO public."schema_migrations" (version) VALUES (20190717192557);
INSERT INTO public."schema_migrations" (version) VALUES (20190719145020);
INSERT INTO public."schema_migrations" (version) VALUES (20190721115735);
INSERT INTO public."schema_migrations" (version) VALUES (20190722201702);
INSERT INTO public."schema_migrations" (version) VALUES (20190724070959);
INSERT INTO public."schema_migrations" (version) VALUES (20190726080205);
INSERT INTO public."schema_migrations" (version) VALUES (20190726100750);
INSERT INTO public."schema_migrations" (version) VALUES (20190807203705);
INSERT INTO public."schema_migrations" (version) VALUES (20190808134256);
INSERT INTO public."schema_migrations" (version) VALUES (20190808170447);
INSERT INTO public."schema_migrations" (version) VALUES (20190808182650);
INSERT INTO public."schema_migrations" (version) VALUES (20190808203925);
INSERT INTO public."schema_migrations" (version) VALUES (20190808203943);
INSERT INTO public."schema_migrations" (version) VALUES (20190808230647);
INSERT INTO public."schema_migrations" (version) VALUES (20190812105340);
INSERT INTO public."schema_migrations" (version) VALUES (20190812131009);
INSERT INTO public."schema_migrations" (version) VALUES (20190814183555);
INSERT INTO public."schema_migrations" (version) VALUES (20190820183734);
INSERT INTO public."schema_migrations" (version) VALUES (20190821221531);
INSERT INTO public."schema_migrations" (version) VALUES (20190823132824);
INSERT INTO public."schema_migrations" (version) VALUES (20190825035721);
INSERT INTO public."schema_migrations" (version) VALUES (20190827110250);
INSERT INTO public."schema_migrations" (version) VALUES (20190827165353);
INSERT INTO public."schema_migrations" (version) VALUES (20190827200558);
INSERT INTO public."schema_migrations" (version) VALUES (20190828170100);
INSERT INTO public."schema_migrations" (version) VALUES (20190828172442);
INSERT INTO public."schema_migrations" (version) VALUES (20190830060401);
INSERT INTO public."schema_migrations" (version) VALUES (20190830061537);
INSERT INTO public."schema_migrations" (version) VALUES (20190830070201);
INSERT INTO public."schema_migrations" (version) VALUES (20190830070256);
INSERT INTO public."schema_migrations" (version) VALUES (20190904171653);
INSERT INTO public."schema_migrations" (version) VALUES (20190904193823);
INSERT INTO public."schema_migrations" (version) VALUES (20190904203029);
INSERT INTO public."schema_migrations" (version) VALUES (20190905222302);
INSERT INTO public."schema_migrations" (version) VALUES (20190906112539);
INSERT INTO public."schema_migrations" (version) VALUES (20190906154041);
INSERT INTO public."schema_migrations" (version) VALUES (20190909014524);
INSERT INTO public."schema_migrations" (version) VALUES (20190911175203);
INSERT INTO public."schema_migrations" (version) VALUES (20190916140329);
INSERT INTO public."schema_migrations" (version) VALUES (20190916172652);
INSERT INTO public."schema_migrations" (version) VALUES (20190916212740);
INSERT INTO public."schema_migrations" (version) VALUES (20190919162428);
INSERT INTO public."schema_migrations" (version) VALUES (20190924151539);
INSERT INTO public."schema_migrations" (version) VALUES (20190925141000);
INSERT INTO public."schema_migrations" (version) VALUES (20190926143708);
INSERT INTO public."schema_migrations" (version) VALUES (20190926150420);
INSERT INTO public."schema_migrations" (version) VALUES (20190926163230);
INSERT INTO public."schema_migrations" (version) VALUES (20190926220911);
INSERT INTO public."schema_migrations" (version) VALUES (20190927105842);
INSERT INTO public."schema_migrations" (version) VALUES (20190929005550);
INSERT INTO public."schema_migrations" (version) VALUES (20190929092719);
INSERT INTO public."schema_migrations" (version) VALUES (20191003132514);
INSERT INTO public."schema_migrations" (version) VALUES (20191017112204);
INSERT INTO public."schema_migrations" (version) VALUES (20191023201835);
INSERT INTO public."schema_migrations" (version) VALUES (20191024163344);
INSERT INTO public."schema_migrations" (version) VALUES (20191025024228);
INSERT INTO public."schema_migrations" (version) VALUES (20191029204707);
INSERT INTO public."schema_migrations" (version) VALUES (20191106185415);
INSERT INTO public."schema_migrations" (version) VALUES (20191107083202);
INSERT INTO public."schema_migrations" (version) VALUES (20191107094958);
INSERT INTO public."schema_migrations" (version) VALUES (20191107101736);
INSERT INTO public."schema_migrations" (version) VALUES (20191108171606);
INSERT INTO public."schema_migrations" (version) VALUES (20191111140900);
INSERT INTO public."schema_migrations" (version) VALUES (20191114203028);
INSERT INTO public."schema_migrations" (version) VALUES (20191121092042);
INSERT INTO public."schema_migrations" (version) VALUES (20191121164228);
INSERT INTO public."schema_migrations" (version) VALUES (20191121172404);
INSERT INTO public."schema_migrations" (version) VALUES (20191125152525);
INSERT INTO public."schema_migrations" (version) VALUES (20191126180144);
INSERT INTO public."schema_migrations" (version) VALUES (20191126191857);
INSERT INTO public."schema_migrations" (version) VALUES (20191202092855);
INSERT INTO public."schema_migrations" (version) VALUES (20191202094810);
INSERT INTO public."schema_migrations" (version) VALUES (20191204155531);
INSERT INTO public."schema_migrations" (version) VALUES (20191210135848);
INSERT INTO public."schema_migrations" (version) VALUES (20191212135903);
INSERT INTO public."schema_migrations" (version) VALUES (20191220085743);
INSERT INTO public."schema_migrations" (version) VALUES (20191220090814);
INSERT INTO public."schema_migrations" (version) VALUES (20191223164815);
INSERT INTO public."schema_migrations" (version) VALUES (20191223165330);
INSERT INTO public."schema_migrations" (version) VALUES (20191223171417);
INSERT INTO public."schema_migrations" (version) VALUES (20191223195213);
INSERT INTO public."schema_migrations" (version) VALUES (20191227083041);
INSERT INTO public."schema_migrations" (version) VALUES (20191227083110);
INSERT INTO public."schema_migrations" (version) VALUES (20191227173748);
INSERT INTO public."schema_migrations" (version) VALUES (20191227174512);
INSERT INTO public."schema_migrations" (version) VALUES (20191227174724);
INSERT INTO public."schema_migrations" (version) VALUES (20191229155319);
INSERT INTO public."schema_migrations" (version) VALUES (20191230160848);
INSERT INTO public."schema_migrations" (version) VALUES (20191231143458);
INSERT INTO public."schema_migrations" (version) VALUES (20200102202337);
INSERT INTO public."schema_migrations" (version) VALUES (20200102204411);
INSERT INTO public."schema_migrations" (version) VALUES (20200103135239);
INSERT INTO public."schema_migrations" (version) VALUES (20200106005818);
INSERT INTO public."schema_migrations" (version) VALUES (20200106143450);
INSERT INTO public."schema_migrations" (version) VALUES (20200113205821);
INSERT INTO public."schema_migrations" (version) VALUES (20200122205145);
INSERT INTO public."schema_migrations" (version) VALUES (20200123084054);
INSERT INTO public."schema_migrations" (version) VALUES (20200128145220);
INSERT INTO public."schema_migrations" (version) VALUES (20200201175549);
INSERT INTO public."schema_migrations" (version) VALUES (20200207110447);
INSERT INTO public."schema_migrations" (version) VALUES (20200223074150);
INSERT INTO public."schema_migrations" (version) VALUES (20200223091432);
INSERT INTO public."schema_migrations" (version) VALUES (20200228040911);
INSERT INTO public."schema_migrations" (version) VALUES (20200302204549);
INSERT INTO public."schema_migrations" (version) VALUES (20200304091636);
INSERT INTO public."schema_migrations" (version) VALUES (20200305101638);
INSERT INTO public."schema_migrations" (version) VALUES (20200309174448);
INSERT INTO public."schema_migrations" (version) VALUES (20200309190800);
INSERT INTO public."schema_migrations" (version) VALUES (20200311143134);
INSERT INTO public."schema_migrations" (version) VALUES (20200311183359);
INSERT INTO public."schema_migrations" (version) VALUES (20200312161107);
INSERT INTO public."schema_migrations" (version) VALUES (20200316050251);
INSERT INTO public."schema_migrations" (version) VALUES (20200316082947);
INSERT INTO public."schema_migrations" (version) VALUES (20200316183228);
INSERT INTO public."schema_migrations" (version) VALUES (20200317095746);
INSERT INTO public."schema_migrations" (version) VALUES (20200319155558);
INSERT INTO public."schema_migrations" (version) VALUES (20200323044752);
INSERT INTO public."schema_migrations" (version) VALUES (20200327074553);
INSERT INTO public."schema_migrations" (version) VALUES (20200401194517);
INSERT INTO public."schema_migrations" (version) VALUES (20200422145700);
INSERT INTO public."schema_migrations" (version) VALUES (20200429160751);
INSERT INTO public."schema_migrations" (version) VALUES (20200520151228);
INSERT INTO public."schema_migrations" (version) VALUES (20200520214127);
INSERT INTO public."schema_migrations" (version) VALUES (20200520214332);
INSERT INTO public."schema_migrations" (version) VALUES (20200521152429);
INSERT INTO public."schema_migrations" (version) VALUES (20200603194807);
INSERT INTO public."schema_migrations" (version) VALUES (20200603214810);
INSERT INTO public."schema_migrations" (version) VALUES (20200608154148);
INSERT INTO public."schema_migrations" (version) VALUES (20200608185338);
INSERT INTO public."schema_migrations" (version) VALUES (20200608190145);
INSERT INTO public."schema_migrations" (version) VALUES (20200610050534);
INSERT INTO public."schema_migrations" (version) VALUES (20200610053757);
INSERT INTO public."schema_migrations" (version) VALUES (20200611154402);
INSERT INTO public."schema_migrations" (version) VALUES (20200612134623);
INSERT INTO public."schema_migrations" (version) VALUES (20200615054739);
INSERT INTO public."schema_migrations" (version) VALUES (20200620150140);
INSERT INTO public."schema_migrations" (version) VALUES (20200622004736);
INSERT INTO public."schema_migrations" (version) VALUES (20200630194601);
