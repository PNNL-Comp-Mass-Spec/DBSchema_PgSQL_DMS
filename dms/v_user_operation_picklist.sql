--
-- Name: v_user_operation_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_user_operation_picklist AS
 SELECT t_user_operations.operation_id AS id,
    t_user_operations.operation AS name,
    t_user_operations.operation_description AS description
   FROM public.t_user_operations;


ALTER TABLE public.v_user_operation_picklist OWNER TO d3l243;

--
-- Name: TABLE v_user_operation_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_user_operation_picklist TO readaccess;

