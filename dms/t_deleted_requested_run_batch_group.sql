--
-- Name: t_deleted_requested_run_batch_group; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_deleted_requested_run_batch_group (
    entry_id integer NOT NULL,
    batch_group_id integer,
    batch_group public.citext NOT NULL,
    description public.citext,
    owner_user_id integer,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_deleted_requested_run_batch_group OWNER TO d3l243;

--
-- Name: t_deleted_requested_run_batch_group_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_deleted_requested_run_batch_group ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_deleted_requested_run_batch_group_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_deleted_requested_run_batch_group pk_t_deleted_requested_run_batch_group; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_deleted_requested_run_batch_group
    ADD CONSTRAINT pk_t_deleted_requested_run_batch_group PRIMARY KEY (entry_id);

ALTER TABLE public.t_deleted_requested_run_batch_group CLUSTER ON pk_t_deleted_requested_run_batch_group;

--
-- Name: TABLE t_deleted_requested_run_batch_group; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_deleted_requested_run_batch_group TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_deleted_requested_run_batch_group TO writeaccess;

