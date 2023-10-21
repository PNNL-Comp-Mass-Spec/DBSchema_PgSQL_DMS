--
-- Name: v_charge_code_owner_dms_user_map; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_charge_code_owner_dms_user_map AS
 SELECT cc.charge_code,
    u.username,
    u.name,
    u.payroll
   FROM (public.t_charge_code cc
     JOIN public.t_users u ON (((('H'::text || (cc.resp_hid)::text))::public.citext OPERATOR(public.=) u.hid)))
  WHERE (u.status OPERATOR(public.<>) 'Obsolete'::public.citext);


ALTER TABLE public.v_charge_code_owner_dms_user_map OWNER TO d3l243;

--
-- Name: TABLE v_charge_code_owner_dms_user_map; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_charge_code_owner_dms_user_map TO readaccess;
GRANT SELECT ON TABLE public.v_charge_code_owner_dms_user_map TO writeaccess;

