--
-- Name: t_project_usage_types; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_project_usage_types (
    project_type_id smallint NOT NULL,
    project_type_name public.citext NOT NULL
);


ALTER TABLE public.t_project_usage_types OWNER TO d3l243;

--
-- Name: TABLE t_project_usage_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_project_usage_types TO readaccess;

