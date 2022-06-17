--
-- Name: v_aux_info_value; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_aux_info_value AS
 SELECT category_target.aux_target AS target,
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
     JOIN public.t_aux_info_subcategory subcategory ON ((category.aux_category_id = subcategory.parent_id)))
     JOIN public.t_aux_info_description item ON ((subcategory.aux_subcategory_id = item.parent_id)))
     JOIN public.t_aux_info_value val ON ((item.aux_description_id = val.aux_info_id)))
     JOIN public.t_aux_info_target category_target ON ((category.target_type_id = category_target.aux_target_id)))
  WHERE (item.active = 'Y'::bpchar);


ALTER TABLE public.v_aux_info_value OWNER TO d3l243;

--
-- Name: TABLE v_aux_info_value; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_aux_info_value TO readaccess;

