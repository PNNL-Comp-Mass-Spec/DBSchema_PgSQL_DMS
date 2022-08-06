--
-- Name: trigfn_t_predefined_analysis_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_predefined_analysis_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the last_affected column in t_predefined_analysis
**
**  Auth:   mem
**  Date:   08/05/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Using <> with columns that can never be null
    -- Otherwise, using IS DISTINCT FROM
    If OLD.analysis_tool_name         <> NEW.analysis_tool_name OR
       OLD.campaign_excl_criteria     <> NEW.campaign_excl_criteria OR
       OLD.campaign_name_criteria     <> NEW.campaign_name_criteria OR
       OLD.dataset_excl_criteria      <> NEW.dataset_excl_criteria OR
       OLD.dataset_name_criteria      <> NEW.dataset_name_criteria OR
       OLD.dataset_type_criteria      <> NEW.dataset_type_criteria OR
       OLD.enabled                    <> NEW.enabled OR
       OLD.exp_comment_criteria       <> NEW.exp_comment_criteria OR
       OLD.experiment_excl_criteria   <> NEW.experiment_excl_criteria OR
       OLD.experiment_name_criteria   <> NEW.experiment_name_criteria OR
       OLD.instrument_class_criteria  <> NEW.instrument_class_criteria OR
       OLD.instrument_name_criteria   <> NEW.instrument_name_criteria OR
       OLD.instrument_excl_criteria   <> NEW.instrument_excl_criteria OR
       OLD.labelling_excl_criteria    <> NEW.labelling_excl_criteria OR
       OLD.labelling_incl_criteria    <> NEW.labelling_incl_criteria OR
       OLD.organism_db_name           <> NEW.organism_db_name OR
       OLD.organism_id                <> NEW.organism_id OR
       OLD.organism_name_criteria     <> NEW.organism_name_criteria OR
       OLD.param_file_name            <> NEW.param_file_name OR
       OLD.predefine_level            <> NEW.predefine_level OR
       OLD.propagation_mode           <> NEW.propagation_mode OR
       OLD.priority                   <> NEW.priority OR
       OLD.protein_collection_list    <> NEW.protein_collection_list OR
       OLD.protein_options_list       <> NEW.protein_options_list OR
       OLD.scan_count_min_criteria    <> NEW.scan_count_min_criteria OR
       OLD.scan_count_max_criteria    <> NEW.scan_count_max_criteria OR
       OLD.separation_type_criteria   <> NEW.separation_type_criteria OR
       OLD.trigger_before_disposition <> NEW.trigger_before_disposition OR
       OLD.next_level                 IS DISTINCT FROM NEW.next_level OR
       OLD.predefine_sequence         IS DISTINCT FROM NEW.predefine_sequence OR
       OLD.settings_file_name         IS DISTINCT FROM NEW.settings_file_name OR
       OLD.special_processing         IS DISTINCT FROM NEW.special_processing Then

        UPDATE t_predefined_analysis
        SET last_affected = CURRENT_TIMESTAMP
        FROM NEW as N
        WHERE t_predefined_analysis.predefine_id = N.predefine_id;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_predefined_analysis_after_update() OWNER TO d3l243;

