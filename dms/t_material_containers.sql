--
-- Name: t_material_containers; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_material_containers (
    container_id integer NOT NULL,
    container public.citext NOT NULL,
    type public.citext NOT NULL,
    comment public.citext,
    rfid_hex_id public.citext GENERATED ALWAYS AS (
CASE
    WHEN (container OPERATOR(public.~~) 'MC-%'::public.citext) THEN "left"(upper((encode((container)::bytea, 'hex'::text) || '000000000000000000000000'::text)), 24)
    ELSE '4D432D303030303030000000'::text
END) STORED NOT NULL,
    location_id integer NOT NULL,
    campaign_id integer,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status public.citext DEFAULT 'Active'::public.citext NOT NULL,
    researcher public.citext,
    sort_key integer GENERATED ALWAYS AS (
CASE
    WHEN (container OPERATOR(public.=) 'Staging'::public.citext) THEN 2147483645
    WHEN (container OPERATOR(public.=) 'Met_Staging'::public.citext) THEN 2147483644
    WHEN (container OPERATOR(public.~~) '%Staging%'::public.citext) THEN (2147483500 + char_length((container)::text))
    WHEN (container OPERATOR(public.=) 'na'::public.citext) THEN 2147483500
    WHEN (container OPERATOR(public.~) similar_to_escape('MC-[0-9]%'::text)) THEN ("substring"((container)::text, 4, 1000))::integer
    WHEN (container OPERATOR(public.~~) 'Bin%'::public.citext) THEN char_length((container)::text)
    ELSE (ascii("substring"((container)::text, 1, 1)) * 10000000)
END) STORED,
    CONSTRAINT ck_t_material_containers_status CHECK (((status OPERATOR(public.=) 'Active'::public.citext) OR (status OPERATOR(public.=) 'Inactive'::public.citext)))
);


ALTER TABLE public.t_material_containers OWNER TO d3l243;

--
-- Name: TABLE t_material_containers; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON TABLE public.t_material_containers IS 'The else clause value of "4D432D303030303030000000" is the text obtained from the following formula: left(upper((encode(''\x4d432d303030303030''::bytea, ''hex'') || ''000000000000000000000000'')), 24)';

--
-- Name: t_material_containers_container_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_material_containers ALTER COLUMN container_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_material_containers_container_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_material_containers pk_t_material_containers; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_material_containers
    ADD CONSTRAINT pk_t_material_containers PRIMARY KEY (container_id);

ALTER TABLE public.t_material_containers CLUSTER ON pk_t_material_containers;

--
-- Name: ix_t_material_containers; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_material_containers ON public.t_material_containers USING btree (container);

--
-- Name: ix_t_material_containers_location_id_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_material_containers_location_id_id ON public.t_material_containers USING btree (location_id, container_id);

--
-- Name: ix_t_material_containers_sort_key; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_material_containers_sort_key ON public.t_material_containers USING btree (sort_key);

--
-- Name: ix_t_material_containers_status; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_material_containers_status ON public.t_material_containers USING btree (status);

--
-- Name: t_material_containers fk_t_material_containers_t_campaign; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_material_containers
    ADD CONSTRAINT fk_t_material_containers_t_campaign FOREIGN KEY (campaign_id) REFERENCES public.t_campaign(campaign_id);

--
-- Name: t_material_containers fk_t_material_containers_t_material_locations; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_material_containers
    ADD CONSTRAINT fk_t_material_containers_t_material_locations FOREIGN KEY (location_id) REFERENCES public.t_material_locations(location_id);

--
-- Name: TABLE t_material_containers; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_material_containers TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_material_containers TO writeaccess;

