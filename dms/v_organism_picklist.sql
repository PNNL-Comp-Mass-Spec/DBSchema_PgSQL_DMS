--
-- Name: v_organism_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_organism_picklist AS
 SELECT organism_id AS id,
    organism AS name,
    description
   FROM public.t_organisms
  WHERE (active > 0);


ALTER VIEW public.v_organism_picklist OWNER TO d3l243;

--
-- Name: TABLE v_organism_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_organism_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_organism_picklist TO writeaccess;

