--
-- Name: v_user_operation_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_user_operation_export AS
 SELECT u.user_id AS id,
    u.username,
    u.hid AS hanford_id,
    u.name,
    u.status,
    permissionsq.operations_list,
    u.comment,
    u.created AS created_dms,
    u.email
   FROM (public.t_users u
     LEFT JOIN ( SELECT opspermissions.user_id,
            string_agg((userops.operation)::text, ', '::text ORDER BY (userops.operation)::text) AS operations_list
           FROM (public.t_user_operations_permissions opspermissions
             JOIN public.t_user_operations userops ON ((opspermissions.operation_id = userops.operation_id)))
          GROUP BY opspermissions.user_id) permissionsq ON ((permissionsq.user_id = u.user_id)));


ALTER TABLE public.v_user_operation_export OWNER TO d3l243;

--
-- Name: VIEW v_user_operation_export; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_user_operation_export IS 'This view is used by the DMS website to lookup user operation permissions for DMS users';

--
-- Name: TABLE v_user_operation_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_user_operation_export TO readaccess;
GRANT SELECT ON TABLE public.v_user_operation_export TO writeaccess;

