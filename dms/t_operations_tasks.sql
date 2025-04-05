--
-- Name: t_operations_tasks; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_operations_tasks (
    task_id integer NOT NULL,
    task_type_id integer DEFAULT 1 NOT NULL,
    task public.citext,
    requester public.citext,
    requested_personnel public.citext,
    assigned_personnel public.citext,
    description public.citext NOT NULL,
    comments public.citext,
    lab_id integer DEFAULT 100 NOT NULL,
    status public.citext DEFAULT 'Normal'::public.citext NOT NULL,
    priority public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
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

ALTER TABLE public.t_operations_tasks CLUSTER ON pk_t_operations_tasks;

--
-- Name: t_operations_tasks fk_t_operations_tasks_t_lab_locations; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_operations_tasks
    ADD CONSTRAINT fk_t_operations_tasks_t_lab_locations FOREIGN KEY (lab_id) REFERENCES public.t_lab_locations(lab_id);

--
-- Name: t_operations_tasks fk_t_operations_tasks_t_operations_task_type; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_operations_tasks
    ADD CONSTRAINT fk_t_operations_tasks_t_operations_task_type FOREIGN KEY (task_type_id) REFERENCES public.t_operations_task_type(task_type_id);

--
-- Name: TABLE t_operations_tasks; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_operations_tasks TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_operations_tasks TO writeaccess;

