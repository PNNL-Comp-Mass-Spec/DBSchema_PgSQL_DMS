--
-- Name: update_requested_run_copy_factors(integer, integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_requested_run_copy_factors(IN _srcrequestid integer, IN _destrequestid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Copy factors from source requested run to destination requested run
**
**  Arguments:
**    _srcRequestID     Source requested run ID
**    _destRequestID    Source requested run ID
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   02/24/2010
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          04/25/2012 mem - Now assuring that _callingUser is not blank
**          11/11/2022 mem - Exclude unnamed factors when querying T_Factor
**          09/13/2023 mem - Only delete factors for the destination requested run if the source requested run actually has factors
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _changeSummary text;
    _usageMessage text := '';
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _srcRequestID   := Coalesce(_srcRequestID, 0);
    _destRequestID  := Coalesce(_destRequestID, 0);
    _callingUser    := Trim(Coalesce(_callingUser, '(copy factors)'));

    -----------------------------------------------------------
    -- Temp table to hold factors being copied
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_Factors (
        Request int,
        Factor text,
        Value text
    );

    -----------------------------------------------------------
    -- Populate temp table
    -----------------------------------------------------------

    INSERT INTO Tmp_Factors (Request, Factor, Value)
    SELECT target_id AS Request,
           name AS Factor,
           value
    FROM t_factor
    WHERE t_factor.Type = 'Run_Request' AND
          target_id = _srcRequestID AND
          Trim(t_factor.name) <> '';

    -----------------------------------------------------------
    -- Get rid of any blank entries from temp table
    -- (shouldn't be any, but let's be cautious)
    -----------------------------------------------------------

    DELETE FROM Tmp_Factors
    WHERE Trim(Coalesce(Value, '')) = '';

    -----------------------------------------------------------
    -- Anything to copy?
    -----------------------------------------------------------

    If Not Exists (SELECT Factor FROM Tmp_Factors) Then
        _message := 'Nothing to copy';

        DROP TABLE Tmp_Factors;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Clean out old factors for _destRequest
    -----------------------------------------------------------

    DELETE FROM t_factor
    WHERE t_factor.type = 'Run_Request' AND
          target_id = _destRequestID;

    -----------------------------------------------------------
    -- Copy from temp table to factors table for _destRequest
    -----------------------------------------------------------

    INSERT INTO t_factor (
        type,
        target_id,
        name,
        value
    )
    SELECT 'Run_Request' AS Type,
           _destRequestID AS TargetID,
           Factor AS Name,
           Value
    FROM Tmp_Factors;

    -----------------------------------------------------------
    -- Convert changed items to XML for logging
    -----------------------------------------------------------

    SELECT string_agg(format('<r i="%s" f="%s" v="%s" />', _destRequestID, Factor, Value), '' ORDER BY Factor)
    INTO _changeSummary
    FROM Tmp_Factors;

    -----------------------------------------------------------
    -- Log changes
    -----------------------------------------------------------

    INSERT INTO t_factor_log (changed_by, changes)
    VALUES (_callingUser, _changeSummary);

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Source: %s; Target: %s', _srcRequestID, _destRequestID);
    CALL post_usage_log_entry ('update_requested_run_copy_factors', _usageMessage);

    DROP TABLE Tmp_Factors;
END
$$;


ALTER PROCEDURE public.update_requested_run_copy_factors(IN _srcrequestid integer, IN _destrequestid integer, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_requested_run_copy_factors(IN _srcrequestid integer, IN _destrequestid integer, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_requested_run_copy_factors(IN _srcrequestid integer, IN _destrequestid integer, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateRequestedRunCopyFactors';

