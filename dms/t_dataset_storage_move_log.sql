--
-- Name: t_dataset_storage_move_log; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_storage_move_log (
    entry_id integer NOT NULL,
    dataset_id integer NOT NULL,
    storage_path_old integer,
    storage_path_new integer,
    archive_path_old integer,
    archive_path_new integer,
    move_cmd public.citext,
    entered timestamp without time zone
);


ALTER TABLE public.t_dataset_storage_move_log OWNER TO d3l243;

--
-- Name: TABLE t_dataset_storage_move_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_storage_move_log TO readaccess;

