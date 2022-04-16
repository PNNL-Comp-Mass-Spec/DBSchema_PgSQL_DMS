--
-- Name: t_internal_standards; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_internal_standards (
    internal_standard_id integer NOT NULL,
    parent_mix_id integer,
    name public.citext NOT NULL,
    description public.citext,
    type public.citext,
    active character(1) NOT NULL
);


ALTER TABLE public.t_internal_standards OWNER TO d3l243;

--
-- Name: TABLE t_internal_standards; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_internal_standards TO readaccess;

