--
-- Name: t_campaign_tracking; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_campaign_tracking (
    campaign_id integer NOT NULL,
    sample_submission_count integer,
    biomaterial_count integer NOT NULL,
    experiment_count integer NOT NULL,
    dataset_count integer NOT NULL,
    job_count integer NOT NULL,
    run_request_count integer NOT NULL,
    sample_prep_request_count integer NOT NULL,
    data_package_count integer,
    sample_submission_most_recent timestamp without time zone,
    biomaterial_most_recent timestamp without time zone,
    experiment_most_recent timestamp without time zone,
    dataset_most_recent timestamp without time zone,
    job_most_recent timestamp without time zone,
    run_request_most_recent timestamp without time zone,
    sample_prep_request_most_recent timestamp without time zone,
    most_recent_activity timestamp without time zone
);


ALTER TABLE public.t_campaign_tracking OWNER TO d3l243;

--
-- Name: t_campaign_tracking pk_t_campaign_tracking; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_campaign_tracking
    ADD CONSTRAINT pk_t_campaign_tracking PRIMARY KEY (campaign_id);

--
-- Name: TABLE t_campaign_tracking; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_campaign_tracking TO readaccess;

