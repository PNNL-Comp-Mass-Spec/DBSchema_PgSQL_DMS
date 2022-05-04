--
-- Name: t_data_analysis_request_batch_ids; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_data_analysis_request_batch_ids (
    request_id integer NOT NULL,
    batch_id integer NOT NULL
);


ALTER TABLE public.t_data_analysis_request_batch_ids OWNER TO d3l243;

--
-- Name: t_data_analysis_request_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_data_analysis_request ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_data_analysis_request_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_data_analysis_request_batch_ids pk_t_data_analysis_request_request_batch_id; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request_batch_ids
    ADD CONSTRAINT pk_t_data_analysis_request_request_batch_id PRIMARY KEY (request_id, batch_id);

--
-- Name: ix_t_data_analysis_request_batch_ids; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_data_analysis_request_batch_ids ON public.t_data_analysis_request_batch_ids USING btree (batch_id, request_id);

--
-- Name: t_data_analysis_request_batch_ids fk_t_data_analysis_request_batch_ids_t_data_analysis_request; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request_batch_ids
    ADD CONSTRAINT fk_t_data_analysis_request_batch_ids_t_data_analysis_request FOREIGN KEY (request_id) REFERENCES public.t_data_analysis_request(id);

--
-- Name: t_data_analysis_request_batch_ids fk_t_data_analysis_request_batch_ids_t_requested_run_batches; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request_batch_ids
    ADD CONSTRAINT fk_t_data_analysis_request_batch_ids_t_requested_run_batches FOREIGN KEY (batch_id) REFERENCES public.t_requested_run_batches(batch_id);

--
-- Name: TABLE t_data_analysis_request_batch_ids; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_data_analysis_request_batch_ids TO readaccess;

