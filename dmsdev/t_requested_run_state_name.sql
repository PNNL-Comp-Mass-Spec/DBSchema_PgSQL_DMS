--
-- Name: t_requested_run_state_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run_state_name (
    state_id smallint NOT NULL,
    state_name public.citext NOT NULL
);


ALTER TABLE public.t_requested_run_state_name OWNER TO d3l243;

--
-- Name: t_requested_run_state_name_state_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_requested_run_state_name ALTER COLUMN state_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_requested_run_state_name_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_requested_run_state_name pk_t_requested_run_state_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_state_name
    ADD CONSTRAINT pk_t_requested_run_state_name PRIMARY KEY (state_id);

ALTER TABLE public.t_requested_run_state_name CLUSTER ON pk_t_requested_run_state_name;

--
-- Name: ix_t_requested_run_state_name_state_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_requested_run_state_name_state_name ON public.t_requested_run_state_name USING btree (state_name);

--
-- Name: TABLE t_requested_run_state_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_state_name TO readaccess;
GRANT SELECT ON TABLE public.t_requested_run_state_name TO writeaccess;

