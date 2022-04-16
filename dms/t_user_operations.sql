--
-- Name: t_user_operations; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_user_operations (
    operation_id integer NOT NULL,
    operation public.citext NOT NULL,
    operation_description public.citext
);


ALTER TABLE public.t_user_operations OWNER TO d3l243;

--
-- Name: TABLE t_user_operations; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_user_operations TO readaccess;

