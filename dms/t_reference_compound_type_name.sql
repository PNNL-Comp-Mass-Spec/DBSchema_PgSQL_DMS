--
-- Name: t_reference_compound_type_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_reference_compound_type_name (
    compound_type_id integer NOT NULL,
    compound_type_name public.citext NOT NULL
);


ALTER TABLE public.t_reference_compound_type_name OWNER TO d3l243;

--
-- Name: TABLE t_reference_compound_type_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_reference_compound_type_name TO readaccess;

