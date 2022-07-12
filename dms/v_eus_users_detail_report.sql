--
-- Name: v_eus_users_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_users_detail_report AS
 SELECT eu.person_id AS id,
    eu.name_fm AS name,
    eu.hid AS hanford_id,
    ss.eus_site_status AS site_status,
    eu.last_affected,
    u.username AS prn,
    u.user_id AS dms_user_id
   FROM ((public.t_eus_users eu
     JOIN public.t_eus_site_status ss ON ((eu.site_status = ss.eus_site_status_id)))
     LEFT JOIN public.t_users u ON ((eu.hid OPERATOR(public.=) u.hid)));


ALTER TABLE public.v_eus_users_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_eus_users_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_users_detail_report TO readaccess;

