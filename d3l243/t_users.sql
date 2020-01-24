--
-- Name: t_users; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_users (
    u_prn public.citext NOT NULL,
    u_name public.citext NOT NULL,
    u_hid public.citext NOT NULL,
    id integer NOT NULL,
    u_status public.citext NOT NULL,
    u_email public.citext,
    u_domain public.citext,
    u_payroll public.citext,
    u_active public.citext NOT NULL,
    u_update public.citext NOT NULL,
    u_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    u_comment public.citext,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    name_with_prn character varying GENERATED ALWAYS AS (((((u_name)::text || ' ('::text) || (u_prn)::text) || ')'::text)) STORED,
    hid_number character varying GENERATED ALWAYS AS ("substring"((u_hid)::text, 2, 20)) STORED
);


ALTER TABLE public.t_users OWNER TO d3l243;

