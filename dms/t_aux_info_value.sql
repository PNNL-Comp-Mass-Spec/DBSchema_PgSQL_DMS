--
-- Name: t_aux_info_value; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_aux_info_value (
    entry_id integer NOT NULL,
    aux_description_id integer NOT NULL,
    value public.citext,
    target_id integer NOT NULL
);


ALTER TABLE public.t_aux_info_value OWNER TO d3l243;

--
-- Name: t_aux_info_value_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_aux_info_value ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_aux_info_value_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_aux_info_value pk_t_aux_info_value; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_aux_info_value
    ADD CONSTRAINT pk_t_aux_info_value PRIMARY KEY (entry_id);

--
-- Name: ix_t_aux_info_value_target_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_aux_info_value_target_id ON public.t_aux_info_value USING btree (target_id, aux_description_id);

--
-- Name: ix_t_aux_info_value_unique_aux_description_id_target_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_aux_info_value_unique_aux_description_id_target_id ON public.t_aux_info_value USING btree (aux_description_id, target_id);

--
-- Name: t_aux_info_value fk_t_aux_info_value_t_aux_info_description; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_aux_info_value
    ADD CONSTRAINT fk_t_aux_info_value_t_aux_info_description FOREIGN KEY (aux_description_id) REFERENCES public.t_aux_info_description(aux_description_id);

--
-- Name: TABLE t_aux_info_value; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_aux_info_value TO readaccess;
GRANT SELECT ON TABLE public.t_aux_info_value TO writeaccess;

