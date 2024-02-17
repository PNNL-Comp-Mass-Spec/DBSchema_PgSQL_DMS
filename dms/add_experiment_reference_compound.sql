--
-- Name: add_experiment_reference_compound(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_experiment_reference_compound(IN _expid integer, IN _updatecachedinfo boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add reference compound entries to database for given experiment
**
**      The calling procedure must create and populate temporary table Tmp_ExpToRefCompoundMap:
**
**      CREATE TEMP TABLE Tmp_ExpToRefCompoundMap (
**          Compound_IDName text not null,          -- This holds compound ID as text; if it is originally of the form '3311:ANFTSQETQGAGK', it will be changed to '3311'
**          Colon_Pos int null,
**          Compound_ID int null
**      );
**
**  Arguments:
**    _expID                Experiment ID
**    _updateCachedInfo     When true, call update_cached_experiment_component_names to update t_cached_experiment_components
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   11/29/2017 mem - Initial release
**          01/04/2018 mem - Update fields in Tmp_ExpToRefCompoundMap, switching from Compound_Name to Compound_IDName
**          12/04/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _invalidRefCompoundList text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If _expID Is Null Then
        _message := 'Experiment ID cannot be null';
        _returnCode := 'U5161';
        RETURN;
    End If;

    _updateCachedInfo := Coalesce(_updateCachedInfo, true);

    ---------------------------------------------------
    -- Try to resolve any null reference compound ID values in Tmp_ExpToRefCompoundMap
    ---------------------------------------------------

    DELETE FROM Tmp_ExpToRefCompoundMap
    WHERE Trim(Coalesce(Compound_IDName, '')) = '';

    -- Make sure column Colon_Pos is populated
    UPDATE Tmp_ExpToRefCompoundMap
    SET Colon_Pos = Position(':' In Compound_IDName)
    WHERE Colon_Pos Is Null;

    -- Update entries in Tmp_ExpToRefCompoundMap to remove extra text that may be present
    -- For example, switch from 3311:ANFTSQETQGAGK to 3311
    UPDATE Tmp_ExpToRefCompoundMap
    SET Compound_IDName = Substring(Compound_IDName, 1, Colon_Pos - 1)
    WHERE Not Colon_Pos Is Null And Colon_Pos > 0 AND Compound_IDName Like '%:%';

    -- Populate the Compound_ID column using any integers in Compound_IDName
    UPDATE Tmp_ExpToRefCompoundMap
    SET Compound_ID = public.try_cast(Compound_IDName, 0)
    WHERE Compound_ID Is Null;

    -- If any entries still have a null Compound_ID value, try matching via reference compound name
    -- We have numerous reference compounds with identical names, so matches found this way will be ambiguous

    UPDATE Tmp_ExpToRefCompoundMap Target
    SET Compound_ID = Src.Compound_ID
    FROM t_reference_compound Src
    WHERE Src.compound_name = Target.Compound_IDName AND
          Target.compound_id IS Null;

    ---------------------------------------------------
    -- Look for invalid entries in Tmp_ExpToRefCompoundMap
    ---------------------------------------------------

    -- First look for entries without a Compound_ID

    SELECT string_agg(Compound_IDName, ', ' ORDER BY Compound_IDName)
    INTO _invalidRefCompoundList
    FROM Tmp_ExpToRefCompoundMap
    WHERE Compound_ID IS NULL;

    If char_length(Coalesce(_invalidRefCompoundList, '')) > 0 Then
        _message := format('Invalid reference compound name(s): %s', _invalidRefCompoundList);
        _returnCode := 'U5163';
        RETURN;
    End If;

    -- Next look for entries with an invalid Compound_ID

    SELECT string_agg(Compound_IDName, ', ' ORDER BY Compound_IDName)
    INTO _invalidRefCompoundList
    FROM Tmp_ExpToRefCompoundMap Src
         LEFT OUTER JOIN t_reference_compound RC
           ON Src.compound_id = RC.compound_id
    WHERE NOT Src.compound_id IS NULL AND
          RC.compound_id IS NULL;

    If char_length(Coalesce(_invalidRefCompoundList, '')) > 0 Then
        _message := format('Invalid reference compound ID(s): %s', _invalidRefCompoundList);
        _returnCode := 'U5164';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Add/remove reference compounds
    ---------------------------------------------------

    DELETE FROM t_experiment_reference_compounds
    WHERE exp_id = _expID;

    INSERT INTO t_experiment_reference_compounds (exp_id, compound_id)
    SELECT DISTINCT _expID AS Exp_ID, Compound_ID
    FROM Tmp_ExpToRefCompoundMap;

    ---------------------------------------------------
    -- Optionally update t_cached_experiment_components
    ---------------------------------------------------

    If _updateCachedInfo Then
        CALL public.update_cached_experiment_component_names (
                        _expID,
                        _infoonly   => false,
                        _message    => _message,        -- Output
                        _returnCode => _returnCode);    -- Output
    End If;

END
$$;


ALTER PROCEDURE public.add_experiment_reference_compound(IN _expid integer, IN _updatecachedinfo boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_experiment_reference_compound(IN _expid integer, IN _updatecachedinfo boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_experiment_reference_compound(IN _expid integer, IN _updatecachedinfo boolean, INOUT _message text, INOUT _returncode text) IS 'AddExperimentReferenceCompound';

