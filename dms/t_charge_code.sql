--
-- Name: t_charge_code; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_charge_code (
    charge_code public.citext NOT NULL,
    resp_prn public.citext,
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
    auth_prn public.citext,
    auth_hid public.citext,
    auto_defined smallint DEFAULT 0 NOT NULL,
    charge_code_state smallint DEFAULT 1 NOT NULL,
    last_affected timestamp without time zone NOT NULL,
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

--
-- Name: ix_t_charge_code_resp_prn; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_charge_code_resp_prn ON public.t_charge_code USING btree (resp_prn);

--
-- Name: ix_t_charge_code_sort_key; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_charge_code_sort_key ON public.t_charge_code USING btree (sort_key);

--
-- Name: TABLE t_charge_code; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_charge_code TO readaccess;

