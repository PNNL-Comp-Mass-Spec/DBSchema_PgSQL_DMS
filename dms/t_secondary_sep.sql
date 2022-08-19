--
-- Name: t_secondary_sep; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_secondary_sep (
    separation_type_id integer NOT NULL,
    separation_type public.citext NOT NULL,
    comment public.citext DEFAULT ''::public.citext NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    separation_group public.citext NOT NULL,
    sample_type_id integer DEFAULT 0 NOT NULL,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_secondary_sep OWNER TO d3l243;

--
-- Name: t_secondary_sep pk_t_secondary_sep; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_secondary_sep
    ADD CONSTRAINT pk_t_secondary_sep PRIMARY KEY (separation_type_id);

--
-- Name: ix_t_secondary_sep; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_secondary_sep ON public.t_secondary_sep USING btree (separation_type);

--
-- Name: t_secondary_sep fk_t_secondary_sep_t_secondary_sep_sample_type; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_secondary_sep
    ADD CONSTRAINT fk_t_secondary_sep_t_secondary_sep_sample_type FOREIGN KEY (sample_type_id) REFERENCES public.t_secondary_sep_sample_type(sample_type_id);

--
-- Name: t_secondary_sep fk_t_secondary_sep_t_separation_group; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_secondary_sep
    ADD CONSTRAINT fk_t_secondary_sep_t_separation_group FOREIGN KEY (separation_group) REFERENCES public.t_separation_group(separation_group) ON UPDATE CASCADE;

--
-- Name: TABLE t_secondary_sep; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_secondary_sep TO readaccess;
GRANT SELECT ON TABLE public.t_secondary_sep TO writeaccess;

