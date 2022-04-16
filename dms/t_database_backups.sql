--
-- Name: t_database_backups; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_database_backups (
    name public.citext NOT NULL,
    backup_folder public.citext NOT NULL,
    full_backup_interval_days double precision NOT NULL,
    last_full_backup timestamp without time zone,
    last_trans_backup timestamp without time zone,
    last_failed_backup timestamp without time zone,
    failed_backup_message public.citext
);


ALTER TABLE public.t_database_backups OWNER TO d3l243;

--
-- Name: TABLE t_database_backups; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_database_backups TO readaccess;

