--
-- Name: v_dataset_type_name_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_type_name_picklist AS
 SELECT t_dataset_type_name.dataset_type_id AS id,
    t_dataset_type_name.dataset_type AS name,
    t_dataset_type_name.description,
    ((((t_dataset_type_name.dataset_type)::text || ' ... "'::text) || (t_dataset_type_name.description)::text) || '"'::text) AS name_with_description
   FROM public.t_dataset_type_name
  WHERE (t_dataset_type_name.active > 0);


ALTER TABLE public.v_dataset_type_name_picklist OWNER TO d3l243;

--
-- Name: TABLE v_dataset_type_name_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_type_name_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_type_name_picklist TO writeaccess;

