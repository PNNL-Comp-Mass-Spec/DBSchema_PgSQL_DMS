--
-- Name: t_misc_paths; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_misc_paths (
    path_id integer NOT NULL,
    path_function public.citext NOT NULL,
    server public.citext,
    client public.citext NOT NULL,
    comment public.citext DEFAULT ''::public.citext NOT NULL
);


ALTER TABLE public.t_misc_paths OWNER TO d3l243;

--
-- Name: t_misc_paths_path_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_misc_paths ALTER COLUMN path_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_misc_paths_path_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_misc_paths pk_t_misc_paths; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_misc_paths
    ADD CONSTRAINT pk_t_misc_paths PRIMARY KEY (path_id);

ALTER TABLE public.t_misc_paths CLUSTER ON pk_t_misc_paths;

--
-- Name: ix_t_misc_paths_path_function; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_misc_paths_path_function ON public.t_misc_paths USING btree (path_function);

--
-- Name: TABLE t_misc_paths; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_misc_paths TO readaccess;
GRANT SELECT ON TABLE public.t_misc_paths TO writeaccess;

