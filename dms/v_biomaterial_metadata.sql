--
-- Name: v_biomaterial_metadata; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_metadata AS
 SELECT u.biomaterial_name AS name,
    u.biomaterial_id AS id,
    u.source_name AS source,
        CASE
            WHEN (u_contact.name IS NULL) THEN u.contact_username
            ELSE u_contact.name_with_username
        END AS source_contact,
    u_pi.name_with_username AS pi,
    btn.biomaterial_type AS type,
    u.reason,
    u.comment,
    c.campaign
   FROM ((((public.t_biomaterial u
     JOIN public.t_biomaterial_type_name btn ON ((u.biomaterial_type_id = btn.biomaterial_type_id)))
     JOIN public.t_campaign c ON ((u.campaign_id = c.campaign_id)))
     LEFT JOIN public.t_users u_contact ON ((u.contact_username OPERATOR(public.=) u_contact.username)))
     LEFT JOIN public.t_users u_pi ON ((u.pi_username OPERATOR(public.=) u_pi.username)));


ALTER TABLE public.v_biomaterial_metadata OWNER TO d3l243;

--
-- Name: TABLE v_biomaterial_metadata; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_metadata TO readaccess;
GRANT SELECT ON TABLE public.v_biomaterial_metadata TO writeaccess;

