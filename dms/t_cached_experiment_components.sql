--
-- Name: t_cached_experiment_components; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_experiment_components (
    exp_id integer NOT NULL,
    biomaterial_list public.citext,
    reference_compound_list public.citext,
    entered timestamp without time zone NOT NULL,
    last_affected timestamp without time zone NOT NULL
);


ALTER TABLE public.t_cached_experiment_components OWNER TO d3l243;

--
-- Name: TABLE t_cached_experiment_components; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_experiment_components TO readaccess;

