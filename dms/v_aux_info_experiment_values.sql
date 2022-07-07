--
-- Name: v_aux_info_experiment_values; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_aux_info_experiment_values AS
 SELECT e.experiment,
    val.target_id AS id,
    category.aux_category AS category,
    subcategory.aux_subcategory AS subcategory,
    item.aux_description AS item,
    val.value
   FROM ((((public.t_aux_info_category category
     JOIN public.t_aux_info_subcategory subcategory ON ((category.aux_category_id = subcategory.parent_id)))
     JOIN public.t_aux_info_description item ON ((subcategory.aux_subcategory_id = item.parent_id)))
     JOIN public.t_aux_info_value val ON ((item.aux_description_id = val.aux_info_id)))
     JOIN public.t_experiments e ON ((val.target_id = e.exp_id)))
  WHERE (category.target_type_id = 500);


ALTER TABLE public.v_aux_info_experiment_values OWNER TO d3l243;

--
-- Name: TABLE v_aux_info_experiment_values; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_aux_info_experiment_values TO readaccess;

