--
-- Name: t_sample_labelling_reporter_ions; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_sample_labelling_reporter_ions (
    label public.citext NOT NULL,
    channel smallint NOT NULL,
    tag_name public.citext NOT NULL,
    masic_name public.citext,
    reporter_ion_mz double precision
);


ALTER TABLE public.t_sample_labelling_reporter_ions OWNER TO d3l243;

--
-- Name: TABLE t_sample_labelling_reporter_ions; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sample_labelling_reporter_ions TO readaccess;

