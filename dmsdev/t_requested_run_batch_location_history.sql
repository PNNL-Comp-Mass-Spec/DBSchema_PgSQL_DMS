--
-- Name: t_requested_run_batch_location_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run_batch_location_history (
    entry_id integer NOT NULL,
    batch_id integer NOT NULL,
    location_id integer NOT NULL,
    first_scan_date timestamp without time zone NOT NULL,
    last_scan_date timestamp without time zone
);


ALTER TABLE public.t_requested_run_batch_location_history OWNER TO d3l243;

--
-- Name: t_requested_run_batch_location_history_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_requested_run_batch_location_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_requested_run_batch_location_history_entry_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_requested_run_batch_location_history pk_t_requested_run_batch_location_history; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_batch_location_history
    ADD CONSTRAINT pk_t_requested_run_batch_location_history PRIMARY KEY (entry_id);

--
-- Name: ix_t_requested_run_batch_location_history_batch_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_batch_location_history_batch_id ON public.t_requested_run_batch_location_history USING btree (batch_id);

--
-- Name: t_requested_run_batch_location_history fk_t_requested_run_batch_location_history_t_material_locations; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_batch_location_history
    ADD CONSTRAINT fk_t_requested_run_batch_location_history_t_material_locations FOREIGN KEY (location_id) REFERENCES public.t_material_locations(location_id);

--
-- Name: TABLE t_requested_run_batch_location_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_batch_location_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_requested_run_batch_location_history TO writeaccess;

