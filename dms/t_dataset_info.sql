--
-- Name: t_dataset_info; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_info (
    dataset_id integer NOT NULL,
    scan_count_ms integer NOT NULL,
    scan_count_msn integer NOT NULL,
    tic_max_ms real,
    tic_max_msn real,
    bpi_max_ms real,
    bpi_max_msn real,
    tic_median_ms real,
    tic_median_msn real,
    bpi_median_ms real,
    bpi_median_msn real,
    elution_time_max real,
    scan_types public.citext,
    last_affected timestamp without time zone NOT NULL,
    profile_scan_count_ms integer,
    profile_scan_count_msn integer,
    centroid_scan_count_ms integer,
    centroid_scan_count_msn integer
);


ALTER TABLE public.t_dataset_info OWNER TO d3l243;

--
-- Name: TABLE t_dataset_info; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_info TO readaccess;

