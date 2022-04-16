--
-- Name: t_emsl_instrument_usage_report; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_emsl_instrument_usage_report (
    seq integer NOT NULL,
    emsl_inst_id integer,
    instrument public.citext,
    dms_inst_id integer NOT NULL,
    type public.citext NOT NULL,
    start timestamp without time zone,
    minutes integer,
    proposal public.citext,
    usage_type_id smallint,
    users public.citext,
    operator public.citext,
    comment public.citext,
    year integer,
    month integer,
    dataset_id integer NOT NULL,
    dataset_id_acq_overlap integer,
    updated timestamp without time zone NOT NULL,
    updated_by public.citext
);


ALTER TABLE public.t_emsl_instrument_usage_report OWNER TO d3l243;

--
-- Name: TABLE t_emsl_instrument_usage_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_emsl_instrument_usage_report TO readaccess;

