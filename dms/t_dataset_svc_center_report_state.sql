--
-- Name: t_dataset_svc_center_report_state; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_svc_center_report_state (
    svc_center_report_state_id smallint NOT NULL,
    svc_center_report_state public.citext NOT NULL,
    description public.citext DEFAULT ''::public.citext NOT NULL
);


ALTER TABLE public.t_dataset_svc_center_report_state OWNER TO d3l243;

--
-- Name: t_dataset_svc_center_report_state pk_t_dataset_svc_center_report_state; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_svc_center_report_state
    ADD CONSTRAINT pk_t_dataset_svc_center_report_state PRIMARY KEY (svc_center_report_state_id);

ALTER TABLE public.t_dataset_svc_center_report_state CLUSTER ON pk_t_dataset_svc_center_report_state;

--
-- Name: ix_t_dataset_svc_center_report_state_svc_center_report_state; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_dataset_svc_center_report_state_svc_center_report_state ON public.t_dataset_svc_center_report_state USING btree (svc_center_report_state);

--
-- Name: TABLE t_dataset_svc_center_report_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_svc_center_report_state TO readaccess;
GRANT SELECT ON TABLE public.t_dataset_svc_center_report_state TO writeaccess;

