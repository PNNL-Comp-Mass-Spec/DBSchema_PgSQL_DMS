--
-- Name: t_user_operations_permissions; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_user_operations_permissions (
    user_id integer NOT NULL,
    operation_id integer NOT NULL
);


ALTER TABLE public.t_user_operations_permissions OWNER TO d3l243;

--
-- Name: TABLE t_user_operations_permissions; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_user_operations_permissions TO readaccess;

