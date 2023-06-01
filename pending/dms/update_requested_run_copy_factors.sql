--
CREATE OR REPLACE PROCEDURE public.update_requested_run_copy_factors
(
    _srcRequestID int,
    _destRequestID int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Copy factors from source requested run to destination requested run
**
**  Auth:   grk
**  Date:   02/24/2010
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          04/25/2012 mem - Now assuring that _callingUser is not blank
**          11/11/2022 mem - Exclude unnamed factors when querying T_Factor
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _changeSummary text;
    _usageMessage text := '';
BEGIN
    _message := '';
    _returnCode := '';

    _callingUser := Coalesce(_callingUser, '(copy factors)');

    -----------------------------------------------------------
    -- Temp table to hold factors being copied
    -----------------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_Factors (
        Request int,
        Factor text,
        Value text
    );

    -----------------------------------------------------------
    -- Populate temp table
    -----------------------------------------------------------
    --
    INSERT INTO Tmp_Factors ( Request, Factor, value )
    SELECT target_id AS Request,
           name AS Factor,
           value
    FROM t_factor
    WHERE t_factor.Type = 'Run_Request' AND
          target_id = _srcRequestID AND
          Trim(T_Factor.Name) <> '';

    -----------------------------------------------------------
    -- Clean out old factors for _destRequest
    -----------------------------------------------------------
    --
    DELETE FROM t_factor
    WHERE t_factor.type = 'Run_Request' AND target_id = _destRequestID;

    -----------------------------------------------------------
    -- Get rid of any blank entries from temp table
    -- (shouldn't be any, but let's be cautious)
    -----------------------------------------------------------
    --
    DELETE FROM Tmp_Factors WHERE Coalesce(Value, '') = '';

    -----------------------------------------------------------
    -- Anything to copy?
    -----------------------------------------------------------
    --
    If Not Exists (SELECT * FROM Tmp_Factors) Then
        _message := 'Nothing to copy';
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Copy from temp table to factors table for _destRequest
    -----------------------------------------------------------
    --
    INSERT INTO t_factor ( type, target_id, name, Value )
    SELECT
        'Run_Request' AS Type, _destRequestID AS TargetID, Factor AS Name, Value
    FROM Tmp_Factors;

    -----------------------------------------------------------
    -- Convert changed items to XML for logging
    -----------------------------------------------------------
    --
    SELECT string_agg(format('<r i="%s" f="%s" v="%s" />', _destRequestID, Factor, Value), '')
    INTO _changeSummary
    FROM Tmp_Factors;

    -----------------------------------------------------------
    -- Log changes
    -----------------------------------------------------------
    --
    INSERT INTO t_factor_log (changed_by, changes)
    VALUES (_callingUser, _changeSummary);

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Source: %s; Target: %s', _srcRequestID, _destRequestID);
    CALL post_usage_log_entry ('Update_Requested_Run_Copy_Factors', _usageMessage);

    DROP TABLE Tmp_Factors;
END
$$;

COMMENT ON PROCEDURE public.update_requested_run_copy_factors IS 'UpdateRequestedRunCopyFactors';
