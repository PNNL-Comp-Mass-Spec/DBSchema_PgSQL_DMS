--
-- Name: t_operations_task_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_operations_task_type (
    task_type_id integer NOT NULL,
    task_type_name public.citext NOT NULL,
    task_type_active smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.t_operations_task_type OWNER TO d3l243;

--
-- Name: t_operations_task_type_task_type_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_operations_task_type ALTER COLUMN task_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_operations_task_type_task_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_operations_task_type pk_t_operations_task_type; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_operations_task_type
    ADD CONSTRAINT pk_t_operations_task_type PRIMARY KEY (task_type_id);

--
-- Name: ix_t_operations_task_type_active; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_operations_task_type_active ON public.t_operations_task_type USING btree (task_type_active, task_type_name);

--
-- Name: ix_t_operations_task_type_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_operations_task_type_name ON public.t_operations_task_type USING btree (task_type_name);

--
-- Name: TABLE t_operations_task_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_operations_task_type TO readaccess;

