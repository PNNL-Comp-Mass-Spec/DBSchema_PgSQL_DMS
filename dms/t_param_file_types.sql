--
-- Name: t_param_file_types; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_param_file_types (
    param_file_type_id integer NOT NULL,
    param_file_type public.citext NOT NULL,
    primary_tool_id integer NOT NULL
);


ALTER TABLE public.t_param_file_types OWNER TO d3l243;

--
-- Name: t_param_file_types pk_t_param_file_types; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_param_file_types
    ADD CONSTRAINT pk_t_param_file_types PRIMARY KEY (param_file_type_id);

--
-- Name: TABLE t_param_file_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_param_file_types TO readaccess;

