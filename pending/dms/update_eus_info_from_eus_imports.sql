--
CREATE OR REPLACE PROCEDURE public.update_eus_info_from_eus_imports
(
    _updateUsersOnInactiveProposals boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Wrapper procedure to call three EUS update procedures:
**      - update_eus_proposals_from_eus_imports
**      - update_eus_users_from_eus_imports
**      - update_eus_instruments_from_eus_imports
**
**      Intended to be manually run on an on-demand basis
**
**  Auth:   mem
**  Date:   03/25/2011 mem - Initial version
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          01/08/2013 mem - Now calling UpdateEUSInstrumentsFromEUSImports
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/12/2021 mem - Add option to update EUS Users for Inactive proposals
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _entryID int := 0;
    _statusMessage text := '';
    _usageMessage text := '';
BEGIN
    _message := '';
    _returnCode := '';

    _updateUsersOnInactiveProposals := Coalesce(_updateUsersOnInactiveProposals, false);

    -- Lookup the highest entry_id in t_log_entries
    SELECT MAX(entry_id) INTO _entryID
    FROM t_log_entries

    If _returnCode = '' Then
        -- Update EUS proposals
        Call update_eus_proposals_from_eus_imports _message => _message

        If _returnCode <> '' And _statusMessage = '' Then
            If _message = '' Then
                _statusMessage := 'Error calling update_eus_proposals_from_eus_imports';
            Else
                _statusMessage := _message;
            End If;
        End If;
    End If;

    If _returnCode = '' Then
        -- Update EUS users
        Call update_eus_users_from_eus_imports _updateUsersOnInactiveProposals, _message => _message

        If _returnCode <> '' And _statusMessage = '' Then
            If _message = '' Then
                _statusMessage := 'Error calling update_eus_users_from_eus_imports';
            Else
                _statusMessage := _message;
            End If;
        End If;
    End If;

    If _returnCode = '' Then
        -- Update EUS instruments
        Call update_eus_instruments_from_eus_imports _message => _message

        If _returnCode <> '' And _statusMessage = '' Then
            If _message = '' Then
                _statusMessage := 'Error calling UpdateEUSInstrumentsFromEUSImports';
            Else
                _statusMessage := _message;
            End If;
        End If;
    End If;

    If _returnCode = '' Then
        If _statusMessage = '' Then
            _statusMessage := 'Update complete';
        End If;

        SELECT _statusMessage AS Message
    Else
        SELECT Coalesce(_message, '??') AS [Error Message]
    End If;

    -- Show any new entries to T_Log_Entrires
    If Exists (Select * from t_log_entries WHERE entry_id > _entryID AND posted_by Like 'UpdateEUS%') Then
        SELECT *
        FROM t_log_entries
        WHERE entry_id > _entryID AND
              posted_by LIKE 'UpdateEUS%'
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Call post_usage_log_entry ('UpdateEUSInfoFromEUSImports', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.update_eus_info_from_eus_imports IS 'UpdateEUSInfoFromEUSImports';
