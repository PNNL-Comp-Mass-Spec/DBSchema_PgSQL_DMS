--
-- Name: t_param_entries; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_param_entries (
    param_entry_id integer NOT NULL,
    entry_sequence_order integer,
    entry_type public.citext,
    entry_specifier public.citext,
    entry_value public.citext,
    param_file_id integer NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_param_entries OWNER TO d3l243;

--
-- Name: t_param_entries_param_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_param_entries ALTER COLUMN param_entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_param_entries_param_entry_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_param_entries pk_t_param_entries; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_param_entries
    ADD CONSTRAINT pk_t_param_entries PRIMARY KEY (param_entry_id);

--
-- Name: t_param_entries trig_t_param_entries_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_param_entries_after_insert AFTER INSERT ON public.t_param_entries REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_param_entries_after_insert();

--
-- Name: t_param_entries trig_t_param_entries_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_param_entries_after_update AFTER UPDATE ON public.t_param_entries FOR EACH ROW WHEN (((old.param_file_id <> new.param_file_id) OR (old.entry_sequence_order IS DISTINCT FROM new.entry_sequence_order) OR (old.entry_type IS DISTINCT FROM new.entry_type) OR (old.entry_specifier IS DISTINCT FROM new.entry_specifier) OR (old.entry_value IS DISTINCT FROM new.entry_value))) EXECUTE FUNCTION public.trigfn_t_param_entries_after_update();

--
-- Name: t_param_entries fk_t_param_entries_t_param_files; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_param_entries
    ADD CONSTRAINT fk_t_param_entries_t_param_files FOREIGN KEY (param_file_id) REFERENCES public.t_param_files(param_file_id) ON UPDATE CASCADE;

--
-- Name: TABLE t_param_entries; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_param_entries TO readaccess;
GRANT SELECT ON TABLE public.t_param_entries TO writeaccess;

