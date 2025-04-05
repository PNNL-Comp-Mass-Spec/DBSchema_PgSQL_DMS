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
    operator integer,
    comment public.citext,
    year integer,
    month integer,
    dataset_id integer NOT NULL,
    dataset_id_acq_overlap integer,
    updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by public.citext
);


ALTER TABLE public.t_emsl_instrument_usage_report OWNER TO d3l243;

--
-- Name: t_emsl_instrument_usage_report pk_t_emsl_instrument_usage_report; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_emsl_instrument_usage_report
    ADD CONSTRAINT pk_t_emsl_instrument_usage_report PRIMARY KEY (seq);

ALTER TABLE public.t_emsl_instrument_usage_report CLUSTER ON pk_t_emsl_instrument_usage_report;

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
-- Name: t_emsl_instrument_usage_report fk_t_emsl_instrument_usage_report_t_emsl_instrument_usage_type; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_emsl_instrument_usage_report
    ADD CONSTRAINT fk_t_emsl_instrument_usage_report_t_emsl_instrument_usage_type FOREIGN KEY (usage_type_id) REFERENCES public.t_emsl_instrument_usage_type(usage_type_id);

--
-- Name: t_emsl_instrument_usage_report fk_t_emsl_instrument_usage_report_t_emsl_instruments; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_emsl_instrument_usage_report
    ADD CONSTRAINT fk_t_emsl_instrument_usage_report_t_emsl_instruments FOREIGN KEY (emsl_inst_id) REFERENCES public.t_emsl_instruments(eus_instrument_id);

--
-- Name: t_emsl_instrument_usage_report fk_t_emsl_instrument_usage_report_t_instrument_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_emsl_instrument_usage_report
    ADD CONSTRAINT fk_t_emsl_instrument_usage_report_t_instrument_name FOREIGN KEY (dms_inst_id) REFERENCES public.t_instrument_name(instrument_id);

--
-- Name: TABLE t_emsl_instrument_usage_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_emsl_instrument_usage_report TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_emsl_instrument_usage_report TO writeaccess;

