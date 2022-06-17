--
-- Name: v_mage_data_package_datasets; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mage_data_package_datasets AS
 SELECT vmd.dataset_id,
    vmd.dataset,
    vmd.experiment,
    vmd.campaign,
    vmd.state,
    vmd.instrument,
    vmd.created,
    vmd.type,
    vmd.folder,
    vmd.comment,
    tpd.data_pkg_id AS data_package_id,
    tpd.package_comment
   FROM (public.v_mage_dataset_list vmd
     JOIN dpkg.t_data_package_datasets tpd ON ((vmd.dataset_id = tpd.dataset_id)));


ALTER TABLE public.v_mage_data_package_datasets OWNER TO d3l243;

--
-- Name: TABLE v_mage_data_package_datasets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mage_data_package_datasets TO readaccess;

