--
-- Name: t_requested_run_status_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run_status_history (
    entry_id integer NOT NULL,
    posting_time timestamp without time zone NOT NULL,
    state_id smallint NOT NULL,
    origin public.citext NOT NULL,
    request_count integer NOT NULL,
    queue_time_0days integer,
    queue_time_1to6days integer,
    queue_time_7to44days integer,
    queue_time_45to89days integer,
    queue_time_90to179days integer,
    queue_time_180days_and_up integer
);


ALTER TABLE public.t_requested_run_status_history OWNER TO d3l243;

--
-- Name: t_requested_run_status_history_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_requested_run_status_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_requested_run_status_history_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_requested_run_status_history pk_t_requested_run_status_history; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_status_history
    ADD CONSTRAINT pk_t_requested_run_status_history PRIMARY KEY (entry_id);

ALTER TABLE public.t_requested_run_status_history CLUSTER ON pk_t_requested_run_status_history;

--
-- Name: ix_t_requested_run_status_history_state_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_requested_run_status_history_state_id ON public.t_requested_run_status_history USING btree (state_id);

--
-- Name: t_requested_run_status_history fk_t_requested_run_status_history_t_requested_run_state_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_status_history
    ADD CONSTRAINT fk_t_requested_run_status_history_t_requested_run_state_name FOREIGN KEY (state_id) REFERENCES public.t_requested_run_state_name(state_id);

--
-- Name: TABLE t_requested_run_status_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_status_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_requested_run_status_history TO writeaccess;

