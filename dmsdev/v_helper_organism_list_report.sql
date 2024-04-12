--
-- Name: v_helper_organism_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_helper_organism_list_report AS
 SELECT organism_id AS id,
    organism AS name,
    genus,
    species,
    strain,
    description,
    created,
    active
   FROM public.t_organisms org
  WHERE (organism OPERATOR(public.<>) '(default)'::public.citext);


ALTER VIEW public.v_helper_organism_list_report OWNER TO d3l243;

--
-- Name: TABLE v_helper_organism_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_helper_organism_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_helper_organism_list_report TO writeaccess;

