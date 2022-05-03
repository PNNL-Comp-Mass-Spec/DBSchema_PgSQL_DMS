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
-- Name: t_dataset_storage_move_log_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_dataset_storage_move_log ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_dataset_storage_move_log_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_dataset_storage_move_log pk_t_dataset_storage_move_log; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_storage_move_log
    ADD CONSTRAINT pk_t_dataset_storage_move_log PRIMARY KEY (entry_id);

--
-- Name: ix_t_dataset_storage_move_log_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_dataset_storage_move_log_dataset_id ON public.t_dataset_storage_move_log USING btree (dataset_id);

--
-- Name: TABLE t_dataset_storage_move_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_storage_move_log TO readaccess;

