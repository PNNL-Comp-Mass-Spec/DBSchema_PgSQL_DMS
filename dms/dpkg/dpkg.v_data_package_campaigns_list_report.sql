--
-- Name: v_data_package_campaigns_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_campaigns_list_report AS
 SELECT DISTINCT dpe.data_pkg_id AS id,
    c.campaign,
    e.campaign_id
   FROM ((dpkg.t_data_package_experiments dpe
     JOIN public.t_experiments e ON ((dpe.experiment_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
UNION
 SELECT DISTINCT dpd.data_pkg_id AS id,
    c.campaign,
    e.campaign_id
   FROM (((dpkg.t_data_package_datasets dpd
     JOIN public.t_dataset d ON ((dpd.dataset_id = d.dataset_id)))
     JOIN public.t_experiments e ON ((d.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)));


ALTER VIEW dpkg.v_data_package_campaigns_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_campaigns_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_campaigns_list_report TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_campaigns_list_report TO writeaccess;

