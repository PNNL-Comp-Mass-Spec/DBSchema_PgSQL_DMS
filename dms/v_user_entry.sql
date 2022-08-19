--
-- Name: v_user_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_user_entry AS
 SELECT t_users.username,
    t_users.hid AS hanford_id,
    'Last Name, First Name, and Email are auto-updated when "User Update" = Y'::text AS entry_note,
    t_users.name AS last_name_first_name,
    t_users.email,
    t_users.status AS user_status,
    t_users.update AS user_update,
    public.get_user_operations_list(t_users.user_id) AS operations_list,
    t_users.comment
   FROM public.t_users;


ALTER TABLE public.v_user_entry OWNER TO d3l243;

--
-- Name: TABLE v_user_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_user_entry TO readaccess;
GRANT SELECT ON TABLE public.v_user_entry TO writeaccess;

