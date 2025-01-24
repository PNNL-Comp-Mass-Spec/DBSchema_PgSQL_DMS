--
-- Name: v_dataset_info_xml; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_dataset_info_xml AS
 SELECT dataset_id,
    ds_info_xml,
    public.try_cast(((xpath('//DatasetInfo/Dataset/text()'::text, ds_info_xml))[1])::text, NULL::text) AS dataset,
    public.try_cast(((xpath('//DatasetInfo/AcquisitionInfo/ScanCount/text()'::text, ds_info_xml))[1])::text, NULL::integer) AS scan_count,
    public.try_cast(((xpath('//DatasetInfo/AcquisitionInfo/ScanCountMS/text()'::text, ds_info_xml))[1])::text, NULL::integer) AS scan_count_ms,
    public.try_cast(((xpath('//DatasetInfo/AcquisitionInfo/ScanCountMSn/text()'::text, ds_info_xml))[1])::text, NULL::integer) AS scan_count_msn,
    public.try_cast(((xpath('//DatasetInfo/AcquisitionInfo/ScanCountDIA/text()'::text, ds_info_xml))[1])::text, NULL::integer) AS scan_count_dia,
    public.try_cast(((xpath('//DatasetInfo/AcquisitionInfo/Elution_Time_Max/text()'::text, ds_info_xml))[1])::text, NULL::numeric) AS elution_time_max,
    public.try_cast(((xpath('//DatasetInfo/AcquisitionInfo/AcqTimeMinutes/text()'::text, ds_info_xml))[1])::text, NULL::numeric) AS acq_time_minutes,
    public.try_cast(((xpath('//DatasetInfo/AcquisitionInfo/StartTime/text()'::text, ds_info_xml))[1])::text, NULL::timestamp without time zone) AS start_time,
    public.try_cast(((xpath('//DatasetInfo/AcquisitionInfo/FileSizeBytes/text()'::text, ds_info_xml))[1])::text, NULL::bigint) AS file_size_bytes,
    public.try_cast(((xpath('//DatasetInfo/AcquisitionInfo/InstrumentFiles/InstrumentFile/text()'::text, ds_info_xml))[1])::text, NULL::text) AS instrument_file,
    public.try_cast(((xpath('//DatasetInfo/AcquisitionInfo/InstrumentFiles/InstrumentFile/@Hash'::text, ds_info_xml))[1])::text, NULL::text) AS instrument_file_hash,
    public.try_cast(((xpath('//DatasetInfo/AcquisitionInfo/InstrumentFiles/InstrumentFile/text()'::text, ds_info_xml))[2])::text, NULL::text) AS instrument_file2,
    public.try_cast(((xpath('//DatasetInfo/AcquisitionInfo/InstrumentFiles/InstrumentFile/@Hash'::text, ds_info_xml))[2])::text, NULL::text) AS instrument_file2_hash,
    cache_date
   FROM cap.t_dataset_info_xml;


ALTER VIEW cap.v_dataset_info_xml OWNER TO d3l243;

--
-- Name: TABLE v_dataset_info_xml; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_dataset_info_xml TO readaccess;
GRANT SELECT ON TABLE cap.v_dataset_info_xml TO writeaccess;

