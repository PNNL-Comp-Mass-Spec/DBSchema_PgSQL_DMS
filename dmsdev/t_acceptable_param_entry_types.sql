--
-- Name: t_acceptable_param_entry_types; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_acceptable_param_entry_types (
    param_entry_type_id integer NOT NULL,
    param_entry_type_name public.citext NOT NULL,
    description public.citext,
    formatting_string public.citext
);


ALTER TABLE public.t_acceptable_param_entry_types OWNER TO d3l243;

--
-- Name: t_acceptable_param_entry_types_param_entry_type_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_acceptable_param_entry_types ALTER COLUMN param_entry_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_acceptable_param_entry_types_param_entry_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_acceptable_param_entry_types pk_t_acceptable_param_entry_types; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_acceptable_param_entry_types
    ADD CONSTRAINT pk_t_acceptable_param_entry_types PRIMARY KEY (param_entry_type_id);

--
-- Name: TABLE t_acceptable_param_entry_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_acceptable_param_entry_types TO readaccess;
GRANT SELECT ON TABLE public.t_acceptable_param_entry_types TO writeaccess;

