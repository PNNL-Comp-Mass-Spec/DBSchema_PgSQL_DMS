--
-- Name: t_storage_path; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_storage_path (
    storage_path_id integer NOT NULL,
    storage_path public.citext NOT NULL,
    machine_name public.citext,
    vol_name_client public.citext,
    vol_name_server public.citext,
    storage_path_function public.citext NOT NULL,
    instrument public.citext,
    storage_path_code public.citext,
    description public.citext,
    url public.citext GENERATED ALWAYS AS (
CASE
    WHEN (storage_path_function OPERATOR(public.~~) '%inbox'::public.citext) THEN NULL::text
    ELSE ((('http://'::text || (machine_name)::text) || '/'::text) || public.replace(storage_path, '\'::public.citext, '/'::public.citext))
END) STORED,
    url_https public.citext GENERATED ALWAYS AS (
CASE
    WHEN (storage_path_function OPERATOR(public.~~) '%inbox'::public.citext) THEN NULL::text
    ELSE (((('https://'::text || (machine_name)::text) ||
    CASE
        WHEN (url_domain OPERATOR(public.=) ''::public.citext) THEN ''::text
        ELSE ('.'::text || (url_domain)::text)
    END) || '/'::text) || public.replace(storage_path, '\'::public.citext, '/'::public.citext))
END) STORED,
    url_domain public.citext DEFAULT ''::public.citext NOT NULL,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.t_storage_path OWNER TO d3l243;

--
-- Name: t_storage_path_storage_path_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_storage_path ALTER COLUMN storage_path_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_storage_path_storage_path_id_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_storage_path pk_t_storage_path; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_storage_path
    ADD CONSTRAINT pk_t_storage_path PRIMARY KEY (storage_path_id);

--
-- Name: ix_t_storage_path_machine_name_path_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_storage_path_machine_name_path_id ON public.t_storage_path USING btree (machine_name, storage_path_id);

--
-- Name: t_storage_path trig_t_storage_path_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_storage_path_after_update AFTER UPDATE ON public.t_storage_path FOR EACH ROW WHEN (((old.storage_path OPERATOR(public.<>) new.storage_path) OR (old.machine_name IS DISTINCT FROM new.machine_name) OR (old.vol_name_client IS DISTINCT FROM new.vol_name_client))) EXECUTE FUNCTION public.trigfn_t_storage_path_after_update();

--
-- Name: t_storage_path fk_t_storage_path_t_instrument_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_storage_path
    ADD CONSTRAINT fk_t_storage_path_t_instrument_name FOREIGN KEY (instrument) REFERENCES public.t_instrument_name(instrument) ON UPDATE CASCADE;

--
-- Name: t_storage_path fk_t_storage_path_t_storage_path_hosts; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_storage_path
    ADD CONSTRAINT fk_t_storage_path_t_storage_path_hosts FOREIGN KEY (machine_name) REFERENCES public.t_storage_path_hosts(sp_machine_name);

--
-- Name: TABLE t_storage_path; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_storage_path TO readaccess;
GRANT SELECT ON TABLE public.t_storage_path TO writeaccess;

