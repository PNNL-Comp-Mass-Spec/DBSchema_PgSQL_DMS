--
-- Name: t_dataset_create_queue_state; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_create_queue_state (
    queue_state_id integer NOT NULL,
    queue_state_name public.citext
);


ALTER TABLE public.t_dataset_create_queue_state OWNER TO d3l243;

--
-- Name: t_dataset_create_queue_state pk_dataset_create_queue_state; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_create_queue_state
    ADD CONSTRAINT pk_dataset_create_queue_state PRIMARY KEY (queue_state_id);

--
-- Name: TABLE t_dataset_create_queue_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_create_queue_state TO readaccess;
GRANT SELECT ON TABLE public.t_dataset_create_queue_state TO writeaccess;

