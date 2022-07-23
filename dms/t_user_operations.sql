--
-- Name: t_user_operations; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_user_operations (
    operation_id integer NOT NULL,
    operation public.citext NOT NULL,
    operation_description public.citext
);


ALTER TABLE public.t_user_operations OWNER TO d3l243;

--
-- Name: t_user_operations_operation_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_user_operations ALTER COLUMN operation_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_user_operations_operation_id_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_user_operations pk_t_user_operations; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_user_operations
    ADD CONSTRAINT pk_t_user_operations PRIMARY KEY (operation_id);

--
-- Name: ix_t_user_operations_unique_operation; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_user_operations_unique_operation ON public.t_user_operations USING btree (operation);

--
-- Name: TABLE t_user_operations; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_user_operations TO readaccess;

