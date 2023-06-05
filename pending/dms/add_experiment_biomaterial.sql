--
CREATE OR REPLACE PROCEDURE public.add_experiment_biomaterial
(
    _expID int,
    _updateCachedInfo boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds biomaterial entries to DB for given experiment
**
**      The calling procedure must create and populate temporary table Tmp_Experiment_to_Biomaterial_Map:
**
**          CREATE TEMP TABLE Tmp_Experiment_to_Biomaterial_Map (
**              Biomaterial_Name text not null,
**              Biomaterial_ID int null
**          )
**
**  Auth:   grk
**  Date:   03/27/2002
**          12/21/2009 grk - Commented out requirement that cell cultures belong to same campaign
**          02/20/2012 mem - Now using a temporary table to track the cell culture names in _cellCultureList
**          02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**          03/17/2017 mem - Pass this procedure's name to Parse_Delimited_List
**          11/29/2017 mem - Remove parameter _cellCultureList and use temporary table Tmp_Experiment_to_Biomaterial_Map instead
**                           Add parameter _updateCachedInfo
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _invalidBiomaterialList text := null;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If _expID Is Null Then
        _message := 'Experiment ID cannot be null';
        _returnCode = 'U5061';
    End If;

    _updateCachedInfo := Coalesce(_updateCachedInfo, true);

    ---------------------------------------------------
    -- Try to resolve any null biomaterial ID values in Tmp_Experiment_to_Biomaterial_Map
    ---------------------------------------------------
    --
    UPDATE Tmp_Experiment_to_Biomaterial_Map Target
    SET Biomaterial_ID = Src.Biomaterial_ID
    FROM T_Biomaterial Src
    WHERE Src.Biomaterial_Name = Target.Biomaterial_Name
          And Target.Biomaterial_ID Is Null;

    ---------------------------------------------------
    -- Look for invalid entries in Tmp_Experiment_to_Biomaterial_Map
    ---------------------------------------------------
    --

    SELECT string_agg(Biomaterial_Name, ', ')
    INTO _invalidBiomaterialList
    FROM Tmp_Experiment_to_Biomaterial_Map
    WHERE Biomaterial_ID IS NULL;

    If char_length(Coalesce(_invalidBiomaterialList, '')) > 0 Then
        _message := format('Invalid biomaterial name(s): %s', _invalidBiomaterialList);
        _returnCode = 'U5063';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Add/remove biomaterial items
    ---------------------------------------------------
    --
    DELETE FROM T_Experiment_Biomaterial
    WHERE Exp_ID = _expID;

    INSERT INTO T_Experiment_Biomaterial (Exp_ID, Biomaterial_ID)
    SELECT DISTINCT _expID As Exp_ID, Biomaterial_ID
    FROM Tmp_Experiment_to_Biomaterial_Map

    ---------------------------------------------------
    -- Optionally update t_cached_experiment_components
    ---------------------------------------------------
    --
    If _updateCachedInfo Then
        CALL update_cached_experiment_component_names _expID
    End If;

END
$$;

COMMENT ON PROCEDURE public.add_experiment_biomaterial IS 'AddExperimentBiomaterial or AddExperimentCellCulture';
