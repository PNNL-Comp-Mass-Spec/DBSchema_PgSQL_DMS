--
-- Name: v_data_package_eus_proposals_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_eus_proposals_list_report AS
 SELECT dpp.data_pkg_id AS id,
    dpp.proposal_id,
    eup.title,
    (public.get_proposal_eus_users_list((eup.proposal_id)::text, 'N'::text, 125))::public.citext AS users,
    s.state_name AS state,
    dpp.item_added
   FROM ((dpkg.t_data_package_eus_proposals dpp
     JOIN public.t_eus_proposals eup ON ((eup.proposal_id OPERATOR(public.=) dpp.proposal_id)))
     JOIN public.t_eus_proposal_state_name s ON ((eup.state_id = s.state_id)));


ALTER VIEW dpkg.v_data_package_eus_proposals_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_eus_proposals_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_eus_proposals_list_report TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_eus_proposals_list_report TO writeaccess;

