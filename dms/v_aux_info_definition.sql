--
-- Name: v_aux_info_definition; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_aux_info_definition AS
 SELECT category_target.target_type_name AS target,
    category.aux_category AS category,
    subcategory.aux_subcategory AS subcategory,
    item.aux_description AS item,
    item.aux_description_id AS item_id,
    category.sequence AS sc,
    subcategory.sequence AS ss,
    item.sequence AS si,
    item.data_size,
    item.helper_append
   FROM (((public.t_aux_info_category category
     JOIN public.t_aux_info_subcategory subcategory ON ((category.aux_category_id = subcategory.aux_category_id)))
     JOIN public.t_aux_info_description item ON ((subcategory.aux_subcategory_id = item.aux_subcategory_id)))
     JOIN public.t_aux_info_target category_target ON ((category.target_type_id = category_target.target_type_id)))
  WHERE (item.active OPERATOR(public.=) 'Y'::public.citext);


ALTER VIEW public.v_aux_info_definition OWNER TO d3l243;

--
-- Name: TABLE v_aux_info_definition; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_aux_info_definition TO readaccess;
GRANT SELECT ON TABLE public.v_aux_info_definition TO writeaccess;

