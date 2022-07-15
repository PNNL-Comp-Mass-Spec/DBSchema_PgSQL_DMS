--
-- Name: v_helper_organism_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_helper_organism_list_report AS
 SELECT org.organism_id AS id,
    org.organism AS name,
    org.genus,
    org.species,
    org.strain,
    org.description,
    org.created,
    org.active
   FROM public.t_organisms org
  WHERE (org.organism OPERATOR(public.<>) '(default)'::public.citext);


ALTER TABLE public.v_helper_organism_list_report OWNER TO d3l243;

--
-- Name: TABLE v_helper_organism_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_helper_organism_list_report TO readaccess;

