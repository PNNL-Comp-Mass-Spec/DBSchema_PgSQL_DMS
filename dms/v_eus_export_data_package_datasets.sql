--
-- Name: v_eus_export_data_package_datasets; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_export_data_package_datasets AS
 SELECT d.dataset_id,
    d.dataset,
    dp.data_pkg_id AS data_package_id,
    dp.package_name AS data_package_name,
    dp.state AS data_package_state,
    rr.eus_proposal_id AS eus_proposal
   FROM (((public.t_dataset d
     JOIN dpkg.t_data_package_datasets dpd ON ((d.dataset_id = dpd.dataset_id)))
     JOIN dpkg.t_data_package dp ON ((dp.data_pkg_id = dpd.data_pkg_id)))
     LEFT JOIN public.t_requested_run rr ON ((rr.dataset_id = d.dataset_id)));


ALTER TABLE public.v_eus_export_data_package_datasets OWNER TO d3l243;

--
-- Name: TABLE v_eus_export_data_package_datasets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_export_data_package_datasets TO readaccess;

