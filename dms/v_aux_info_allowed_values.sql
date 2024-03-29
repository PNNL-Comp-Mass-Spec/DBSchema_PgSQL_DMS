--
-- Name: v_aux_info_allowed_values; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_aux_info_allowed_values AS
 SELECT category_target.target_type_name AS target,
    category.aux_category AS category,
    subcategory.aux_subcategory AS subcategory,
    item.aux_description AS item,
    allowedvals.value AS allowed_value
   FROM ((((public.t_aux_info_category category
     JOIN public.t_aux_info_subcategory subcategory ON ((category.aux_category_id = subcategory.aux_category_id)))
     JOIN public.t_aux_info_description item ON ((subcategory.aux_subcategory_id = item.aux_subcategory_id)))
     JOIN public.t_aux_info_target category_target ON ((category.target_type_id = category_target.target_type_id)))
     JOIN public.t_aux_info_allowed_values allowedvals ON ((item.aux_description_id = allowedvals.aux_description_id)));


ALTER VIEW public.v_aux_info_allowed_values OWNER TO d3l243;

--
-- Name: TABLE v_aux_info_allowed_values; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_aux_info_allowed_values TO readaccess;
GRANT SELECT ON TABLE public.v_aux_info_allowed_values TO writeaccess;

