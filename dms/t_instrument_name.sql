--
-- Name: t_instrument_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_name (
    instrument_id integer NOT NULL,
    instrument public.citext NOT NULL,
    instrument_class public.citext NOT NULL,
    instrument_group public.citext DEFAULT 'Other'::public.citext NOT NULL,
    source_path_id integer,
    storage_path_id integer,
    capture_method public.citext,
    status public.citext DEFAULT 'active'::bpchar,
    room_number public.citext,
    description public.citext,
    usage public.citext DEFAULT ''::public.citext NOT NULL,
    operations_role public.citext DEFAULT 'Unknown'::public.citext NOT NULL,
    tracking smallint DEFAULT 0 NOT NULL,
    percent_emsl_owned integer DEFAULT 0 NOT NULL,
    max_simultaneous_captures smallint DEFAULT 1 NOT NULL,
    capture_exclusion_window real DEFAULT 11 NOT NULL,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    auto_define_storage_path smallint DEFAULT 0 NOT NULL,
    auto_sp_vol_name_client public.citext,
    auto_sp_vol_name_server public.citext,
    auto_sp_path_root public.citext,
    auto_sp_url_domain public.citext DEFAULT ''::public.citext NOT NULL,
    auto_sp_archive_server_name public.citext,
    auto_sp_archive_path_root public.citext,
    auto_sp_archive_share_path_root public.citext,
    default_purge_policy smallint DEFAULT 0 NOT NULL,
    perform_calibration smallint DEFAULT 0 NOT NULL,
    scan_source_dir smallint DEFAULT 1 NOT NULL,
    building public.citext GENERATED ALWAYS AS (
CASE
    WHEN (POSITION((' '::text) IN (room_number)) > 1) THEN "substring"((room_number)::text, 1, (POSITION((' '::text) IN (room_number)) - 1))
    ELSE (room_number)::text
END) STORED,
    default_purge_priority smallint DEFAULT 3 NOT NULL,
    storage_purge_holdoff_months smallint DEFAULT 1 NOT NULL,
    CONSTRAINT ck_t_instrument_name_status CHECK (((status OPERATOR(public.=) 'offline'::public.citext) OR (status OPERATOR(public.=) 'inactive'::public.citext) OR (status OPERATOR(public.=) 'active'::public.citext) OR (status OPERATOR(public.=) 'broken'::public.citext)))
);


ALTER TABLE public.t_instrument_name OWNER TO d3l243;

--
-- Name: t_instrument_name pk_t_instrument_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_name
    ADD CONSTRAINT pk_t_instrument_name PRIMARY KEY (instrument_id);

--
-- Name: ix_t_instrument_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_instrument_name ON public.t_instrument_name USING btree (instrument);

--
-- Name: ix_t_instrument_name_class_name_instrument_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_instrument_name_class_name_instrument_id ON public.t_instrument_name USING btree (instrument_class, instrument, instrument_id);

--
-- Name: t_instrument_name fk_t_instrument_name_t_instrument_class; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_name
    ADD CONSTRAINT fk_t_instrument_name_t_instrument_class FOREIGN KEY (instrument_class) REFERENCES public.t_instrument_class(instrument_class) ON UPDATE CASCADE;

--
-- Name: t_instrument_name fk_t_instrument_name_t_instrument_name_instrument_group; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_name
    ADD CONSTRAINT fk_t_instrument_name_t_instrument_name_instrument_group FOREIGN KEY (instrument_group) REFERENCES public.t_instrument_group(instrument_group) ON UPDATE CASCADE;

--
-- Name: t_instrument_name fk_t_instrument_name_t_instrument_ops_role; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_name
    ADD CONSTRAINT fk_t_instrument_name_t_instrument_ops_role FOREIGN KEY (operations_role) REFERENCES public.t_instrument_ops_role(role);

--
-- Name: t_instrument_name fk_t_instrument_name_t_storage_path_source_path_id; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_name
    ADD CONSTRAINT fk_t_instrument_name_t_storage_path_source_path_id FOREIGN KEY (source_path_id) REFERENCES public.t_storage_path(storage_path_id);

--
-- Name: t_instrument_name fk_t_instrument_name_t_storage_path_storage_path_id; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_name
    ADD CONSTRAINT fk_t_instrument_name_t_storage_path_storage_path_id FOREIGN KEY (storage_path_id) REFERENCES public.t_storage_path(storage_path_id);

--
-- Name: t_instrument_name fk_t_instrument_name_t_yes_no; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_name
    ADD CONSTRAINT fk_t_instrument_name_t_yes_no FOREIGN KEY (auto_define_storage_path) REFERENCES public.t_yes_no(flag);

--
-- Name: TABLE t_instrument_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_name TO readaccess;
GRANT SELECT ON TABLE public.t_instrument_name TO writeaccess;

