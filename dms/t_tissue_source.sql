--
-- Name: t_tissue_source; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_tissue_source (
    tissue_source_id smallint NOT NULL,
    tissue_source public.citext NOT NULL
);


ALTER TABLE public.t_tissue_source OWNER TO d3l243;

--
-- Name: TABLE t_tissue_source; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_tissue_source TO readaccess;

