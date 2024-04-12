--
-- Name: v_user_operation_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_user_operation_picklist AS
 SELECT operation_id AS id,
    operation AS name,
    operation_description AS description
   FROM public.t_user_operations;


ALTER VIEW public.v_user_operation_picklist OWNER TO d3l243;

--
-- Name: TABLE v_user_operation_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_user_operation_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_user_operation_picklist TO writeaccess;

