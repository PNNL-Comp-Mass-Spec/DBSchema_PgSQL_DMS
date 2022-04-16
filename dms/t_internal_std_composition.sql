--
-- Name: t_internal_std_composition; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_internal_std_composition (
    mix_id integer NOT NULL,
    component_id integer NOT NULL,
    concentration public.citext
);


ALTER TABLE public.t_internal_std_composition OWNER TO d3l243;

--
-- Name: TABLE t_internal_std_composition; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_internal_std_composition TO readaccess;

