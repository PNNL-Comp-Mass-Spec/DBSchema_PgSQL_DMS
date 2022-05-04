--
-- Name: t_data_analysis_request; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_data_analysis_request (
    id integer NOT NULL,
    request_name public.citext NOT NULL,
    analysis_type public.citext DEFAULT 'Metabolomics'::public.citext NOT NULL,
    requester_prn public.citext,
    description public.citext DEFAULT ''::public.citext NOT NULL,
    analysis_specifications public.citext,
    comment public.citext,
    representative_batch_id integer,
    data_package_id integer,
    exp_group_id integer,
    work_package public.citext,
    requested_personnel public.citext,
    assigned_personnel public.citext DEFAULT ''::public.citext,
    priority public.citext DEFAULT 'Normal'::public.citext,
    reason_for_high_priority public.citext,
    estimated_analysis_time_days integer DEFAULT 1 NOT NULL,
    state smallint DEFAULT 1 NOT NULL,
    state_comment public.citext,
    created timestamp without time zone NOT NULL,
    state_changed timestamp without time zone NOT NULL,
    closed timestamp without time zone,
    campaign public.citext,
    organism public.citext,
    eus_proposal_id public.citext,
    dataset_count integer
);


ALTER TABLE public.t_data_analysis_request OWNER TO d3l243;

--
-- Name: t_data_analysis_request pk_t_data_analysis_request; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request
    ADD CONSTRAINT pk_t_data_analysis_request PRIMARY KEY (id);

--
-- Name: TABLE t_data_analysis_request; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_data_analysis_request TO readaccess;

