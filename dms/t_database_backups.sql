--
-- Name: t_database_backups; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_database_backups (
    name public.citext NOT NULL,
    backup_folder public.citext NOT NULL,
    full_backup_interval_days double precision DEFAULT 14 NOT NULL,
    last_full_backup timestamp without time zone,
    last_trans_backup timestamp without time zone,
    last_failed_backup timestamp without time zone,
    failed_backup_message public.citext
);


ALTER TABLE public.t_database_backups OWNER TO d3l243;

--
-- Name: t_database_backups pk_t_database_backups; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_database_backups
    ADD CONSTRAINT pk_t_database_backups PRIMARY KEY (name, backup_folder);

ALTER TABLE public.t_database_backups CLUSTER ON pk_t_database_backups;

--
-- Name: TABLE t_database_backups; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_database_backups TO readaccess;
GRANT SELECT ON TABLE public.t_database_backups TO writeaccess;

