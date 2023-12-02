--
-- Name: v_lab_locations; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lab_locations AS
 SELECT t_lab_locations.lab_name,
    t_lab_locations.lab_description,
    t_lab_locations.sort_weight
   FROM public.t_lab_locations
  WHERE (t_lab_locations.lab_active > 0);


ALTER VIEW public.v_lab_locations OWNER TO d3l243;

--
-- Name: TABLE v_lab_locations; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lab_locations TO readaccess;
GRANT SELECT ON TABLE public.v_lab_locations TO writeaccess;

