--
-- Name: t_users; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_users (
    user_id integer NOT NULL,
    prn public.citext NOT NULL,
    username public.citext NOT NULL,
    hid public.citext NOT NULL,
    status public.citext DEFAULT 'Active'::public.citext NOT NULL,
    email public.citext,
    domain public.citext,
    payroll public.citext,
    active public.citext DEFAULT 'Y'::public.citext NOT NULL,
    update public.citext DEFAULT 'Y'::public.citext NOT NULL,
    created timestamp without time zone,
    comment public.citext DEFAULT ''::public.citext,
    last_affected timestamp without time zone,
    name_with_prn public.citext GENERATED ALWAYS AS (((((username)::text || ' ('::text) || (prn)::text) || ')'::text)) STORED,
    hid_number public.citext GENERATED ALWAYS AS ("substring"((hid)::text, 2, 20)) STORED
);


ALTER TABLE public.t_users OWNER TO d3l243;

--
-- Name: t_users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_users ALTER COLUMN user_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_users_user_id_seq
    START WITH 2000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_users ix_t_users_unique_prn; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_users
    ADD CONSTRAINT ix_t_users_unique_prn UNIQUE (prn);

--
-- Name: t_users pk_t_users; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_users
    ADD CONSTRAINT pk_t_users PRIMARY KEY (user_id);

--
-- Name: ix_t_users_username; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_users_username ON public.t_users USING btree (username);

--
-- Name: t_users fk_t_users_t_user_status; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_users
    ADD CONSTRAINT fk_t_users_t_user_status FOREIGN KEY (status) REFERENCES public.t_user_status(user_status);

--
-- Name: TABLE t_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_users TO readaccess;

