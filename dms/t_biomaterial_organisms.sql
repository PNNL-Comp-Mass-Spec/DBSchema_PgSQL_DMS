--
-- Name: t_biomaterial_organisms; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_biomaterial_organisms (
    organism_id integer NOT NULL,
    biomaterial_id integer NOT NULL
);


ALTER TABLE public.t_biomaterial_organisms OWNER TO d3l243;

--
-- Name: TABLE t_biomaterial_organisms; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_biomaterial_organisms TO readaccess;

