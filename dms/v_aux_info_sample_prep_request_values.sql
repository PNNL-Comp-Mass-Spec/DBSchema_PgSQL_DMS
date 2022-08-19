--
-- Name: v_aux_info_sample_prep_request_values; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_aux_info_sample_prep_request_values AS
 SELECT spr.request_name AS request,
    val.target_id AS id,
    category.aux_category AS category,
    subcategory.aux_subcategory AS subcategory,
    item.aux_description AS item,
    val.value
   FROM ((((public.t_aux_info_category category
     JOIN public.t_aux_info_subcategory subcategory ON ((category.aux_category_id = subcategory.aux_category_id)))
     JOIN public.t_aux_info_description item ON ((subcategory.aux_subcategory_id = item.aux_subcategory_id)))
     JOIN public.t_aux_info_value val ON ((item.aux_description_id = val.aux_description_id)))
     JOIN public.t_sample_prep_request spr ON ((val.target_id = spr.prep_request_id)))
  WHERE (category.target_type_id = 503);


ALTER TABLE public.v_aux_info_sample_prep_request_values OWNER TO d3l243;

--
-- Name: TABLE v_aux_info_sample_prep_request_values; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_aux_info_sample_prep_request_values TO readaccess;
GRANT SELECT ON TABLE public.v_aux_info_sample_prep_request_values TO writeaccess;

