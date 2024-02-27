--
-- Name: t_requested_run_batch_group; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run_batch_group (
    batch_group_id integer NOT NULL,
    batch_group public.citext NOT NULL,
    description public.citext,
    owner_user_id integer,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_requested_run_batch_group OWNER TO d3l243;

--
-- Name: t_requested_run_batch_group_batch_group_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_requested_run_batch_group ALTER COLUMN batch_group_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_requested_run_batch_group_batch_group_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_requested_run_batch_group pk_t_requested_run_batch_group; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_batch_group
    ADD CONSTRAINT pk_t_requested_run_batch_group PRIMARY KEY (batch_group_id);

--
-- Name: ix_t_requested_run_batch_group; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_requested_run_batch_group ON public.t_requested_run_batch_group USING btree (batch_group);

--
-- Name: t_requested_run_batch_group fk_t_requested_run_batch_group_t_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run_batch_group
    ADD CONSTRAINT fk_t_requested_run_batch_group_t_users FOREIGN KEY (owner_user_id) REFERENCES public.t_users(user_id);

--
-- Name: TABLE t_requested_run_batch_group; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run_batch_group TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_requested_run_batch_group TO writeaccess;

