--
-- Name: v_eus_user_id_lookup; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_user_id_lookup AS
 SELECT u.username,
    u.hid AS hanford_id,
    u.name,
    u.user_id AS dms_user_id,
    u.created AS created_dms,
    u.status AS dms_status,
    lookupq.eus_person_id,
    lookupq.eus_name,
    lookupq.eus_site_status
   FROM (public.t_users u
     JOIN ( SELECT eu.person_id AS eus_person_id,
            eu.name_fm AS eus_name,
            ess.eus_site_status,
            eu.hid AS eus_hanford_id,
            row_number() OVER (PARTITION BY eu.hid ORDER BY eu.person_id DESC) AS rowrank
           FROM (public.t_eus_site_status ess
             JOIN public.t_eus_users eu ON ((ess.eus_site_status_id = eu.site_status_id)))
          WHERE ((NOT (eu.hid IS NULL)) AND (eu.valid = 1))) lookupq ON (((lookupq.eus_hanford_id OPERATOR(public.=) u.hid) AND (lookupq.rowrank = 1))));


ALTER TABLE public.v_eus_user_id_lookup OWNER TO d3l243;

--
-- Name: VIEW v_eus_user_id_lookup; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_eus_user_id_lookup IS 'A few users have multiple EUS Person_ID values. We use LookupQ.RowRank = 1 when joining to the subquery to just keep one of those rows. This logic is also used by V_User_Detail_Report';

--
-- Name: TABLE v_eus_user_id_lookup; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_user_id_lookup TO readaccess;
GRANT SELECT ON TABLE public.v_eus_user_id_lookup TO writeaccess;

