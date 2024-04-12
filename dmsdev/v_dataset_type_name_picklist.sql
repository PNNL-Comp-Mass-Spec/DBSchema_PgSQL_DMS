--
-- Name: v_dataset_type_name_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_type_name_picklist AS
 SELECT dataset_type_id AS id,
    dataset_type AS name,
    description,
    (((((((((dataset_type)::text || (' ... "'::public.citext)::text))::public.citext)::text || (description)::text))::public.citext)::text || ('"'::public.citext)::text))::public.citext AS name_with_description
   FROM public.t_dataset_type_name
  WHERE (active > 0);


ALTER VIEW public.v_dataset_type_name_picklist OWNER TO d3l243;

--
-- Name: TABLE v_dataset_type_name_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_type_name_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_type_name_picklist TO writeaccess;

