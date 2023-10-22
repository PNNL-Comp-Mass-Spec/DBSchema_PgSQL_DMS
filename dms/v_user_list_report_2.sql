--
-- Name: v_user_list_report_2; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_user_list_report_2 AS
 SELECT u.user_id AS id,
    u.username,
    u.hid AS hanford_id,
    u.name,
    u.status,
    (public.get_user_operations_list(u.user_id))::public.citext AS operations_list,
    u.comment,
    u.created AS created_dms,
    eu.person_id AS eus_id,
    eu.valid AS valid_eus_id,
    ess.eus_site_status AS eus_status,
    u.email
   FROM ((public.t_eus_site_status ess
     JOIN public.t_eus_users eu ON ((ess.eus_site_status_id = eu.site_status_id)))
     RIGHT JOIN public.t_users u ON ((eu.hid OPERATOR(public.=) u.hid)));


ALTER TABLE public.v_user_list_report_2 OWNER TO d3l243;

--
-- Name: VIEW v_user_list_report_2; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_user_list_report_2 IS 'Note that a few DMS Users have multiple EUS Person_ID values. That leads to duplicate rows in this report, but it doesn"t hurt anything (and is actually informative)';

--
-- Name: TABLE v_user_list_report_2; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_user_list_report_2 TO readaccess;
GRANT SELECT ON TABLE public.v_user_list_report_2 TO writeaccess;

