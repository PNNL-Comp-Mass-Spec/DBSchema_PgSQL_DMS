--
-- Name: v_requested_run_batch_group_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_group_picklist AS
 SELECT batch_group_id AS id,
    batch_group,
    (((((((batch_group_id)::public.citext)::text || (': '::public.citext)::text))::public.citext)::text || (batch_group)::text))::public.citext AS id_with_batch_group
   FROM public.t_requested_run_batch_group;


ALTER VIEW public.v_requested_run_batch_group_picklist OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_group_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_group_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_batch_group_picklist TO writeaccess;

