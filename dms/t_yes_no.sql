--
-- Name: t_yes_no; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_yes_no (
    flag smallint NOT NULL,
    description public.citext NOT NULL
);


ALTER TABLE public.t_yes_no OWNER TO d3l243;

--
-- Name: TABLE t_yes_no; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_yes_no TO readaccess;

