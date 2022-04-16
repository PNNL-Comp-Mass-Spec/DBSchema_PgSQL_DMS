--
-- Name: t_modification_types; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_modification_types (
    mod_type_symbol character(1) NOT NULL,
    description public.citext,
    mod_type_synonym public.citext
);


ALTER TABLE public.t_modification_types OWNER TO d3l243;

--
-- Name: TABLE t_modification_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_modification_types TO readaccess;

