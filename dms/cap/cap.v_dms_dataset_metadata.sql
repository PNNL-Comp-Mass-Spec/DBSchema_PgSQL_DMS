--
-- Name: v_dms_dataset_metadata; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_dms_dataset_metadata AS
 SELECT ds.dataset,
    ds.dataset_id,
    dstypename.dataset_type AS type,
    ds.folder_name AS folder,
    instname.instrument_class,
    instname.instrument AS instrument_name,
    instname.capture_method AS method,
    instname.max_simultaneous_captures,
    instname.capture_exclusion_window,
    edm.eus_instrument_id,
    rr.eus_proposal_id,
    ds.operator_username,
    COALESCE(eusproposaluserrr.eus_user_id, eususeroperator.eus_person_id) AS eus_operator_id,
    ds.created,
    sourcepath.storage_path AS source_path,
    sourcepath.vol_name_server AS source_vol,
    sourcepath.storage_path_id AS source_path_id,
    storagepath.machine_name AS storage_server_name,
    storagepath.vol_name_server AS storage_vol,
    storagepath.storage_path,
    storagepath.vol_name_client AS storage_vol_external,
    storagepath.storage_path_id,
    archivepath.archive_server_name AS archive_server,
    archivepath.archive_path,
    archivepath.network_share_path AS archive_network_share_path,
    archivepath.archive_path_id
   FROM ((((((((((public.t_dataset ds
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_type_name dstypename ON ((ds.dataset_type_id = dstypename.dataset_type_id)))
     JOIN public.t_storage_path sourcepath ON ((instname.source_path_id = sourcepath.storage_path_id)))
     JOIN public.t_storage_path storagepath ON ((storagepath.storage_path_id = ds.storage_path_id)))
     LEFT JOIN public.t_dataset_archive da ON ((ds.dataset_id = da.dataset_id)))
     LEFT JOIN public.t_archive_path archivepath ON ((da.storage_path_id = archivepath.archive_path_id)))
     LEFT JOIN public.t_emsl_dms_instrument_mapping edm ON ((ds.instrument_id = edm.dms_instrument_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     LEFT JOIN public.v_eus_user_id_lookup eususeroperator ON ((ds.operator_username OPERATOR(public.=) eususeroperator.username)))
     LEFT JOIN public.v_eus_proposal_user_lookup eusproposaluserrr ON (((rr.eus_proposal_id OPERATOR(public.=) eusproposaluserrr.proposal_id) AND (ds.operator_username OPERATOR(public.=) eusproposaluserrr.username) AND (eusproposaluserrr.valid_eus_id > 0))));


ALTER TABLE cap.v_dms_dataset_metadata OWNER TO d3l243;

--
-- Name: VIEW v_dms_dataset_metadata; Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON VIEW cap.v_dms_dataset_metadata IS 'This view shows metadata about datasets and is used when creating capture task jobs';

--
-- Name: TABLE v_dms_dataset_metadata; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_dms_dataset_metadata TO readaccess;
GRANT SELECT ON TABLE cap.v_dms_dataset_metadata TO writeaccess;

