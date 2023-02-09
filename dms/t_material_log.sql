--
-- Name: t_material_log; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_material_log (
    entry_id integer NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type public.citext NOT NULL,
    item public.citext NOT NULL,
    initial_state public.citext,
    final_state public.citext,
    username public.citext,
    comment public.citext,
    item_type public.citext GENERATED ALWAYS AS (
CASE
    WHEN (type OPERATOR(public.~~) 'B Material%'::public.citext) THEN 'Biomaterial'::public.citext
    WHEN (type OPERATOR(public.~~) 'Biomaterial%'::public.citext) THEN 'Biomaterial'::public.citext
    WHEN (type OPERATOR(public.~~) 'E Material%'::public.citext) THEN 'Experiment'::public.citext
    WHEN (type OPERATOR(public.~~) 'Experiment%'::public.citext) THEN 'Experiment'::public.citext
    WHEN (type OPERATOR(public.~~) 'R Material%'::public.citext) THEN 'RefCompound'::public.citext
    WHEN (type OPERATOR(public.~~) 'Reference Compound%'::public.citext) THEN 'RefCompound'::public.citext
    WHEN (type OPERATOR(public.~~) 'Container%'::public.citext) THEN 'Container'::public.citext
    WHEN (type OPERATOR(public.~~) '%Container'::public.citext) THEN 'Container'::public.citext
    ELSE type
END) STORED,
    type_name_cached public.citext GENERATED ALWAYS AS (
CASE
    WHEN (type OPERATOR(public.=) 'B Material Move'::public.citext) THEN 'Biomaterial Move'::public.citext
    WHEN (type OPERATOR(public.=) 'B Material Retirement'::public.citext) THEN 'Biomaterial Retirement'::public.citext
    WHEN (type OPERATOR(public.=) 'E Material Move'::public.citext) THEN 'Experiment Move'::public.citext
    WHEN (type OPERATOR(public.=) 'E Material Retirement'::public.citext) THEN 'Experiment Retirement'::public.citext
    WHEN (type OPERATOR(public.=) 'R Material Move'::public.citext) THEN 'RefCompound Move'::public.citext
    WHEN (type OPERATOR(public.=) 'R Material Retirement'::public.citext) THEN 'RefCompound Retirement'::public.citext
    ELSE type
END) STORED
);


ALTER TABLE public.t_material_log OWNER TO d3l243;

--
-- Name: t_material_log_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_material_log ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_material_log_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_material_log pk_t_material_log; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_material_log
    ADD CONSTRAINT pk_t_material_log PRIMARY KEY (entry_id);

--
-- Name: ix_t_material_log_item_type_date; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_material_log_item_type_date ON public.t_material_log USING btree (item_type, date);

--
-- Name: ix_t_material_log_type_name_cached_date; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_material_log_type_name_cached_date ON public.t_material_log USING btree (type_name_cached, date);

--
-- Name: TABLE t_material_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_material_log TO readaccess;
GRANT SELECT ON TABLE public.t_material_log TO writeaccess;

