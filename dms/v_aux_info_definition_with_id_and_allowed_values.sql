--
-- Name: v_aux_info_definition_with_id_and_allowed_values; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_aux_info_definition_with_id_and_allowed_values AS
 SELECT category_target.target_type_name AS target,
    category.target_type_id,
    category.aux_category AS category,
    category.aux_category_id AS cat_id,
    subcategory.aux_subcategory AS subcategory,
    subcategory.aux_subcategory_id AS sub_id,
    item.aux_description AS item,
    item.aux_description_id AS item_id,
    category.sequence AS cat_seq,
    subcategory.sequence AS sub_seq,
    item.sequence AS item_seq,
    item.data_size,
    item.helper_append,
    public.get_aux_info_allowed_values(item.aux_description_id) AS allowed_values
   FROM (((public.t_aux_info_category category
     JOIN public.t_aux_info_subcategory subcategory ON ((category.aux_category_id = subcategory.aux_category_id)))
     JOIN public.t_aux_info_description item ON ((subcategory.aux_subcategory_id = item.aux_subcategory_id)))
     JOIN public.t_aux_info_target category_target ON ((category.target_type_id = category_target.target_type_id)))
  WHERE (item.active OPERATOR(public.=) 'Y'::public.citext);


ALTER VIEW public.v_aux_info_definition_with_id_and_allowed_values OWNER TO d3l243;

--
-- Name: TABLE v_aux_info_definition_with_id_and_allowed_values; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_aux_info_definition_with_id_and_allowed_values TO readaccess;
GRANT SELECT ON TABLE public.v_aux_info_definition_with_id_and_allowed_values TO writeaccess;

