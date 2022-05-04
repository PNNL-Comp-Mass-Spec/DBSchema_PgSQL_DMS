--
-- Name: t_operations_tasks; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_operations_tasks (
    task_id integer NOT NULL,
    tab public.citext,
    requester public.citext,
    requested_personnel public.citext,
    assigned_personnel public.citext,
    description public.citext NOT NULL,
    comments public.citext,
    status public.citext DEFAULT 'Normal'::public.citext NOT NULL,
    priority public.citext,
    created timestamp without time zone,
    work_package public.citext,
    closed timestamp without time zone,
    hours_spent public.citext
);


ALTER TABLE public.t_operations_tasks OWNER TO d3l243;

--
-- Name: t_operations_tasks_task_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_operations_tasks ALTER COLUMN task_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_operations_tasks_task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_operations_tasks pk_t_operations_tasks; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_operations_tasks
    ADD CONSTRAINT pk_t_operations_tasks PRIMARY KEY (task_id);

--
-- Name: TABLE t_operations_tasks; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_operations_tasks TO readaccess;

