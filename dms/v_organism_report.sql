--
-- Name: v_organism_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_organism_report AS
 SELECT t_organisms.organism AS name,
    t_organisms.organism_db_path AS org_db_file_storage_path_client,
    ''::text AS org_db_file_storage_path_server,
    t_organisms.organism_db_name AS default_org_db_file_name
   FROM public.t_organisms;


ALTER VIEW public.v_organism_report OWNER TO d3l243;

--
-- Name: TABLE v_organism_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_organism_report TO readaccess;
GRANT SELECT ON TABLE public.v_organism_report TO writeaccess;

