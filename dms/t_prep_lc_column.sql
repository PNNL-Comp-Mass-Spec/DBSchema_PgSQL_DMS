--
-- Name: t_prep_lc_column; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_prep_lc_column (
    prep_column_id integer NOT NULL,
    prep_column public.citext NOT NULL,
    mfg_name public.citext,
    mfg_model public.citext,
    mfg_serial public.citext,
    packing_mfg public.citext NOT NULL,
    packing_type public.citext NOT NULL,
    particle_size public.citext NOT NULL,
    particle_type public.citext NOT NULL,
    column_inner_dia public.citext NOT NULL,
    column_outer_dia public.citext NOT NULL,
    length public.citext NOT NULL,
    state public.citext NOT NULL,
    operator_prn public.citext NOT NULL,
    comment public.citext,
    created timestamp without time zone NOT NULL
);


ALTER TABLE public.t_prep_lc_column OWNER TO d3l243;

--
-- Name: TABLE t_prep_lc_column; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_prep_lc_column TO readaccess;

