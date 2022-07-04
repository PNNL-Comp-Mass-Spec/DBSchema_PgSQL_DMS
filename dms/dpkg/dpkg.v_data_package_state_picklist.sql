--
-- Name: v_data_package_state_picklist; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_state_picklist AS
 SELECT t_data_package_state.state_name,
    t_data_package_state.description
   FROM dpkg.t_data_package_state;


ALTER TABLE dpkg.v_data_package_state_picklist OWNER TO d3l243;

