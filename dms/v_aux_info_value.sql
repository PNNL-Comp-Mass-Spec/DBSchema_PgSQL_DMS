--
-- Name: v_aux_info_value; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_aux_info_value AS
 SELECT category_target.target_type_name AS target,
    val.target_id,
    category.aux_category AS category,
    subcategory.aux_subcategory AS subcategory,
    item.aux_description AS item,
    val.value,
    category.sequence AS sc,
    subcategory.sequence AS ss,
    item.sequence AS si,
    item.data_size,
    item.helper_append
   FROM ((((public.t_aux_info_category category
     JOIN public.t_aux_info_subcategory subcategory ON ((category.aux_category_id = subcategory.aux_category_id)))
     JOIN public.t_aux_info_description item ON ((subcategory.aux_subcategory_id = item.aux_subcategory_id)))
     JOIN public.t_aux_info_value val ON ((item.aux_description_id = val.aux_description_id)))
     JOIN public.t_aux_info_target category_target ON ((category.target_type_id = category_target.target_type_id)))
  WHERE (item.active OPERATOR(public.=) 'Y'::public.citext);


ALTER TABLE public.v_aux_info_value OWNER TO d3l243;

--
-- Name: TABLE v_aux_info_value; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_aux_info_value TO readaccess;
GRANT SELECT ON TABLE public.v_aux_info_value TO writeaccess;

