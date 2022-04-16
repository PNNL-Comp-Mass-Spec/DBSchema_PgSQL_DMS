--
-- Name: t_users; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_users (
    user_id integer NOT NULL,
    prn public.citext NOT NULL,
    username public.citext NOT NULL,
    hid public.citext NOT NULL,
    status public.citext NOT NULL,
    email public.citext,
    domain public.citext,
    payroll public.citext,
    active public.citext NOT NULL,
    update public.citext NOT NULL,
    created timestamp without time zone,
    comment public.citext,
    last_affected timestamp without time zone,
    name_with_prn public.citext GENERATED ALWAYS AS (((((username)::text || ' ('::text) || (prn)::text) || ')'::text)) STORED,
    hid_number public.citext GENERATED ALWAYS AS ("substring"((hid)::text, 2, 20)) STORED
);


ALTER TABLE public.t_users OWNER TO d3l243;

--
-- Name: TABLE t_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_users TO readaccess;

