--
-- Name: t_emsl_instrument_usage_report; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_emsl_instrument_usage_report (
    seq integer NOT NULL,
    emsl_inst_id integer,
    instrument public.citext,
    dms_inst_id integer DEFAULT 1 NOT NULL,
    type public.citext NOT NULL,
    start timestamp without time zone,
    minutes integer,
    proposal public.citext,
    usage_type_id smallint DEFAULT 1,
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
-- Name: t_emsl_instrument_usage_report pk_t_emsl_instrument_usage_report; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_emsl_instrument_usage_report
    ADD CONSTRAINT pk_t_emsl_instrument_usage_report PRIMARY KEY (seq);

--
-- Name: ix_t_emsl_instrument_usage_report; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_emsl_instrument_usage_report ON public.t_emsl_instrument_usage_report USING btree (year, month, dms_inst_id, start);

--
-- Name: ix_t_emsl_instrument_usage_report_dms_inst_id_start; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_emsl_instrument_usage_report_dms_inst_id_start ON public.t_emsl_instrument_usage_report USING btree (dms_inst_id, start);

--
-- Name: ix_t_emsl_instrument_usage_report_type_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_emsl_instrument_usage_report_type_dataset_id ON public.t_emsl_instrument_usage_report USING btree (type, dataset_id);

--
-- Name: TABLE t_emsl_instrument_usage_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_emsl_instrument_usage_report TO readaccess;

