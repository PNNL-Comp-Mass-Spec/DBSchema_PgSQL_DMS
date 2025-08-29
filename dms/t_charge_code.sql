--
-- Name: t_charge_code; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_charge_code (
    charge_code public.citext NOT NULL,
    resp_username public.citext,
    resp_hid public.citext,
    wbs_title public.citext,
    charge_code_title public.citext,
    sub_account public.citext,
    sub_account_title public.citext,
    setup_date timestamp without time zone NOT NULL,
    sub_account_effective_date timestamp without time zone,
    inactive_date timestamp without time zone,
    sub_account_inactive_date timestamp without time zone,
    inactive_date_most_recent timestamp without time zone,
    deactivated public.citext DEFAULT 'N'::public.citext NOT NULL,
    auth_amt bigint NOT NULL,
    auth_username public.citext,
    auth_hid public.citext,
    auto_defined smallint DEFAULT 0 NOT NULL,
    charge_code_state smallint DEFAULT 1 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usage_sample_prep integer,
    usage_requested_run integer,
    activation_state smallint DEFAULT 0 NOT NULL,
    sort_key public.citext GENERATED ALWAYS AS (((
CASE
    WHEN ((activation_state = 3) OR (activation_state = 0)) THEN '0'::public.citext
    ELSE '1'::public.citext
END)::text || (((activation_state)::public.citext)::text || (charge_code)::text))) STORED
);


ALTER TABLE public.t_charge_code OWNER TO d3l243;

--
-- Name: t_charge_code pk_t_charge_code; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_charge_code
    ADD CONSTRAINT pk_t_charge_code PRIMARY KEY (charge_code);

ALTER TABLE public.t_charge_code CLUSTER ON pk_t_charge_code;

--
-- Name: ix_t_charge_code_resp_username; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_charge_code_resp_username ON public.t_charge_code USING btree (resp_username);

--
-- Name: ix_t_charge_code_sort_key; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_charge_code_sort_key ON public.t_charge_code USING btree (sort_key);

--
-- Name: t_charge_code trig_t_charge_code_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_charge_code_after_update AFTER UPDATE ON public.t_charge_code FOR EACH ROW WHEN (((old.activation_state <> new.activation_state) OR (old.deactivated OPERATOR(public.<>) new.deactivated) OR (old.charge_code_state <> new.charge_code_state) OR (old.inactive_date IS DISTINCT FROM new.inactive_date) OR (old.usage_sample_prep IS DISTINCT FROM new.usage_sample_prep) OR (old.usage_requested_run IS DISTINCT FROM new.usage_requested_run))) EXECUTE FUNCTION public.trigfn_t_charge_code_after_update();

--
-- Name: t_charge_code fk_t_charge_code_t_charge_code_activation_state; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_charge_code
    ADD CONSTRAINT fk_t_charge_code_t_charge_code_activation_state FOREIGN KEY (activation_state) REFERENCES public.t_charge_code_activation_state(activation_state);

--
-- Name: t_charge_code fk_t_charge_code_t_charge_code_state; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_charge_code
    ADD CONSTRAINT fk_t_charge_code_t_charge_code_state FOREIGN KEY (charge_code_state) REFERENCES public.t_charge_code_state(charge_code_state);

--
-- Name: TABLE t_charge_code; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_charge_code TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_charge_code TO writeaccess;

