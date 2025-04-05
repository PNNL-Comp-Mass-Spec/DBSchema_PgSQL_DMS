--
-- Name: t_deleted_requested_run_batch; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_deleted_requested_run_batch (
    entry_id integer NOT NULL,
    batch_id integer NOT NULL,
    batch public.citext NOT NULL,
    description public.citext,
    owner_user_id integer,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    locked public.citext DEFAULT 'Yes'::public.citext NOT NULL,
    last_ordered timestamp without time zone,
    requested_batch_priority public.citext DEFAULT 'Normal'::public.citext NOT NULL,
    actual_batch_priority public.citext DEFAULT 'Normal'::public.citext NOT NULL,
    requested_completion_date timestamp without time zone,
    justification_for_high_priority public.citext,
    comment public.citext,
    batch_group_id integer,
    batch_group_order integer,
    deleted timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.t_deleted_requested_run_batch OWNER TO d3l243;

--
-- Name: t_deleted_requested_run_batch_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_deleted_requested_run_batch ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_deleted_requested_run_batch_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_deleted_requested_run_batch pk_t_deleted_requested_run_batch; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_deleted_requested_run_batch
    ADD CONSTRAINT pk_t_deleted_requested_run_batch PRIMARY KEY (entry_id);

ALTER TABLE public.t_deleted_requested_run_batch CLUSTER ON pk_t_deleted_requested_run_batch;

--
-- Name: TABLE t_deleted_requested_run_batch; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_deleted_requested_run_batch TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_deleted_requested_run_batch TO writeaccess;

