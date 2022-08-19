--
-- Name: t_sample_submission; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_sample_submission (
    submission_id integer NOT NULL,
    campaign_id integer NOT NULL,
    received_by_user_id integer NOT NULL,
    container_list public.citext,
    description public.citext,
    storage_id integer,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_sample_submission OWNER TO d3l243;

--
-- Name: t_sample_submission_submission_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_sample_submission ALTER COLUMN submission_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_sample_submission_submission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_sample_submission pk_t_sample_submission; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_submission
    ADD CONSTRAINT pk_t_sample_submission PRIMARY KEY (submission_id);

--
-- Name: t_sample_submission fk_t_sample_submission_t_campaign; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_submission
    ADD CONSTRAINT fk_t_sample_submission_t_campaign FOREIGN KEY (campaign_id) REFERENCES public.t_campaign(campaign_id);

--
-- Name: t_sample_submission fk_t_sample_submission_t_prep_file_storage; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_submission
    ADD CONSTRAINT fk_t_sample_submission_t_prep_file_storage FOREIGN KEY (storage_id) REFERENCES public.t_prep_file_storage(storage_id);

--
-- Name: t_sample_submission fk_t_sample_submission_t_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_submission
    ADD CONSTRAINT fk_t_sample_submission_t_users FOREIGN KEY (received_by_user_id) REFERENCES public.t_users(user_id);

--
-- Name: TABLE t_sample_submission; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sample_submission TO readaccess;
GRANT SELECT ON TABLE public.t_sample_submission TO writeaccess;

