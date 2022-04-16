--
-- Name: t_instrument_group; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_group (
    instrument_group public.citext NOT NULL,
    usage public.citext,
    comment public.citext,
    active smallint NOT NULL,
    default_dataset_type integer,
    allocation_tag public.citext,
    sample_prep_visible smallint NOT NULL,
    requested_run_visible smallint NOT NULL,
    target_instrument_group public.citext
);


ALTER TABLE public.t_instrument_group OWNER TO d3l243;

--
-- Name: TABLE t_instrument_group; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_group TO readaccess;

