--
-- Name: v_dataset_type_name_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_type_name_export AS
 SELECT t_dataset_type_name.dataset_type_id,
    t_dataset_type_name.dataset_type,
    t_dataset_type_name.description,
    t_dataset_type_name.active
   FROM public.t_dataset_type_name;


ALTER TABLE public.v_dataset_type_name_export OWNER TO d3l243;

--
-- Name: TABLE v_dataset_type_name_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_type_name_export TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_type_name_export TO writeaccess;

