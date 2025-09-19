--
-- Name: v_dataset_rating_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_rating_list_report AS
 SELECT dataset_rating_id AS id,
    dataset_rating,
    comment
   FROM public.t_dataset_rating_name;


ALTER VIEW public.v_dataset_rating_list_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_rating_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_rating_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_rating_list_report TO writeaccess;

