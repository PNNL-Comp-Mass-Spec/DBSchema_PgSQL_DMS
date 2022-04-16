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
    status public.citext NOT NULL,
    priority public.citext,
    created timestamp without time zone,
    work_package public.citext,
    closed timestamp without time zone,
    hours_spent public.citext
);


ALTER TABLE public.t_operations_tasks OWNER TO d3l243;

--
-- Name: TABLE t_operations_tasks; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_operations_tasks TO readaccess;

