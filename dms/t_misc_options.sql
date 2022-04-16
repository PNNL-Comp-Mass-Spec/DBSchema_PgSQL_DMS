--
-- Name: t_misc_options; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_misc_options (
    name public.citext NOT NULL,
    id integer NOT NULL,
    value public.citext NOT NULL,
    comment public.citext
);


ALTER TABLE public.t_misc_options OWNER TO d3l243;

--
-- Name: TABLE t_misc_options; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_misc_options TO readaccess;

