--
-- Name: t_campaign_tracking; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_campaign_tracking (
    campaign_id integer NOT NULL,
    sample_submission_count integer DEFAULT 0,
    biomaterial_count integer DEFAULT 0 NOT NULL,
    experiment_count integer DEFAULT 0 NOT NULL,
    dataset_count integer DEFAULT 0 NOT NULL,
    job_count integer DEFAULT 0 NOT NULL,
    run_request_count integer DEFAULT 0 NOT NULL,
    sample_prep_request_count integer DEFAULT 0 NOT NULL,
    data_package_count integer DEFAULT 0,
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

ALTER TABLE public.t_campaign_tracking CLUSTER ON pk_t_campaign_tracking;

--
-- Name: TABLE t_campaign_tracking; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_campaign_tracking TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_campaign_tracking TO writeaccess;

