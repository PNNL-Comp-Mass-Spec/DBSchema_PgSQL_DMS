--
-- Name: v_user_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_user_detail_report AS
 SELECT u.username,
    u.hid AS hanford_id,
    u.name,
    u.email,
    u.status AS user_status,
    u.update AS user_update,
    public.get_user_operations_list(u.user_id) AS operations_list,
    u.comment,
    u.user_id AS id,
    u.created AS created_dms,
    lookupq.eus_person_id,
    lookupq.eus_site_status,
    lookupq.eus_last_affected
   FROM (public.t_users u
     LEFT JOIN ( SELECT eu.hid,
            eu.person_id AS eus_person_id,
            ess.eus_site_status,
            eu.last_affected AS eus_last_affected,
            row_number() OVER (PARTITION BY eu.hid ORDER BY eu.person_id DESC) AS rowrank
           FROM (public.t_eus_site_status ess
             JOIN public.t_eus_users eu ON ((ess.eus_site_status_id = eu.site_status_id)))
          WHERE ((NOT (eu.hid IS NULL)) AND (eu.valid = 1))) lookupq ON (((lookupq.hid OPERATOR(public.=) u.hid) AND (lookupq.rowrank = 1))));


ALTER TABLE public.v_user_detail_report OWNER TO d3l243;

--
-- Name: VIEW v_user_detail_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_user_detail_report IS 'A few users have multiple EUS Person_ID values. Use LookupQ.RowRank = 1 when joining to the subquery to just keep one of those rows. This logic is also used by V_EUS_User_ID_Lookup. We also exclude users with EU.Valid = 0';

--
-- Name: TABLE v_user_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_user_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_user_detail_report TO writeaccess;

