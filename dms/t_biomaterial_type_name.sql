--
-- Name: t_biomaterial_type_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_biomaterial_type_name (
    biomaterial_type_id integer NOT NULL,
    biomaterial_type public.citext NOT NULL
);


ALTER TABLE public.t_biomaterial_type_name OWNER TO d3l243;

--
-- Name: TABLE t_biomaterial_type_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_biomaterial_type_name TO readaccess;

