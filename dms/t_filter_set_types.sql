--
-- Name: t_filter_set_types; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_filter_set_types (
    filter_type_id integer NOT NULL,
    filter_type_name public.citext NOT NULL
);


ALTER TABLE public.t_filter_set_types OWNER TO d3l243;

--
-- Name: t_filter_set_types_filter_type_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_filter_set_types ALTER COLUMN filter_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_filter_set_types_filter_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_filter_set_types pk_t_filter_set_types; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_filter_set_types
    ADD CONSTRAINT pk_t_filter_set_types PRIMARY KEY (filter_type_id);

--
-- Name: TABLE t_filter_set_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_filter_set_types TO readaccess;
GRANT SELECT ON TABLE public.t_filter_set_types TO writeaccess;

