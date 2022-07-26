--
-- Name: v_users_pnnl; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_users_pnnl AS
 SELECT src."EMPLID" AS employee_id,
    u.user_id AS dms_user_id,
    src."HANFORD_ID",
    src."BUSINESS_TITLE" AS title,
    src."PREFERRED_NAME_FM" AS person_name,
    src."INTERNET_EMAIL_ADDRESS" AS email,
    src."NETWORK_DOMAIN",
    src."NETWORK_ID",
    src."PNNL_PAY_NO" AS payroll_number,
    COALESCE(src."ACTIVE_SW", 'N'::character varying) AS active,
    src."COMPANY",
    src."PRIMARY_BLD_NO" AS building,
    src."PRIMARY_ROOM_NO" AS room,
    src."PRIMARY_WORK_PHONE" AS phone,
    src."REPORTING_MGR_EMPLID" AS mgr_employee_id,
    src."COR_CD" AS cost_code,
    src."COR_AMOUNT" AS cost_amount
   FROM (pnnldata."VW_PUB_BMI_EMPLOYEE" src
     LEFT JOIN public.t_users u ON (((u.hid)::text = ('H'::text || (src."HANFORD_ID")::text))));


ALTER TABLE public.v_users_pnnl OWNER TO d3l243;

--
-- Name: VIEW v_users_pnnl; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_users_pnnl IS 'This view retrieves data from the operation warehouse database (OPWHSE) on server SQLSrvProd02';

--
-- Name: TABLE v_users_pnnl; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_users_pnnl TO readaccess;

