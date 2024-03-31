--
-- Name: v_mrm_list_attachment_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mrm_list_attachment_list_report AS
 SELECT attachment_id AS id,
    attachment_name AS name,
    attachment_description AS description,
    owner_username AS owner,
    active,
    created
   FROM public.t_attachments
  WHERE (attachment_type OPERATOR(public.=) 'MRM Transition List'::public.citext);


ALTER VIEW public.v_mrm_list_attachment_list_report OWNER TO d3l243;

--
-- Name: TABLE v_mrm_list_attachment_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mrm_list_attachment_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_mrm_list_attachment_list_report TO writeaccess;

