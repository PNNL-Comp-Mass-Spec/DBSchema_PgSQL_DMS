--
-- Name: v_dataset_type_name_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_type_name_export AS
 SELECT dataset_type_id,
    dataset_type,
    description,
    active
   FROM public.t_dataset_type_name;


ALTER VIEW public.v_dataset_type_name_export OWNER TO d3l243;

--
-- Name: TABLE v_dataset_type_name_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_type_name_export TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_type_name_export TO writeaccess;

