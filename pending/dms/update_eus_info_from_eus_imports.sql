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
**      Intended to be manually run, as needed
**
**  Arguments:
**    _updateUsersOnInactiveProposals   When true, update_eus_users_from_eus_imports will update all proposals in t_eus_proposals, including inactive proposals
**                                      However, skips those with state 4 ('no interest')
**    _message                          Status message
**    _returnCode                       Return code
**
**  Auth:   mem
**  Date:   03/25/2011 mem - Initial version
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          01/08/2013 mem - Now calling Update_EUS_Instruments_From_EUS_Imports
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/12/2021 mem - Add option to update EUS Users for Inactive proposals
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _entryID int := 0;
    _statusMessage text := '';
    _usageMessage text := '';

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _updateUsersOnInactiveProposals := Coalesce(_updateUsersOnInactiveProposals, false);

    -- Lookup the most recent entry_id in t_log_entries
    SELECT MAX(entry_id)
    INTO _entryID
    FROM t_log_entries;

    -- Update EUS proposals
    CALL public.update_eus_proposals_from_eus_imports (
                    _message => _message,           -- Output
                    _returnCode => _returnCode);    -- Output

    If _returnCode <> '' And _statusMessage = '' Then
        If _message = '' Then
            _statusMessage := 'Error calling update_eus_proposals_from_eus_imports';
        Else
            _statusMessage := _message;
        End If;
    End If;

    If _returnCode = '' Then
        -- Update EUS users
        CALL public.update_eus_users_from_eus_imports (
                        _updateUsersOnInactiveProposals,
                        _message => _message,           -- Output
                        _returnCode => _returnCode);    -- Output

        If _returnCode <> '' And _statusMessage = '' Then
            If _message = '' Then
                _statusMessage := 'Error calling Update_EUS_Users_From_EUS_Imports';
            Else
                _statusMessage := _message;
            End If;
        End If;
    End If;

    If _returnCode = '' Then
        -- Update EUS instruments
        CALL public.update_eus_instruments_from_eus_imports (
                        _message => _message,           -- Output
                        _returnCode => _returnCode);    -- Output

        If _returnCode <> '' And _statusMessage = '' Then
            If _message = '' Then
                _statusMessage := 'Error calling Update_EUS_Instruments_From_EUS_Imports';
            Else
                _statusMessage := _message;
            End If;
        End If;
    End If;

    If _returnCode = '' Then
        If _statusMessage = '' Then
            _statusMessage := 'Update complete';
        End If;

        RAISE INFO '%', _statusMessage;
    Else
        RAISE INFO 'Return code %: %', _returnCode, Coalesce(_message, '??');
    End If;

    -- Show any new entries in T_Log_Entries

    If Exists (SELECT entry_id FROM t_log_entries WHERE entry_id > _entryID AND posted_by ILIKE 'Update%EUS%') Then
        RAISE INFO '';

        _formatSpecifier := '%-12s %-40s %-20s %-10s %-60s';

        _infoHead := format(_formatSpecifier,
                            'Entry_ID',
                            'Posted_By',
                            'Entered',
                            'Type',
                            'Message'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '------------',
                                     '----------------------------------------',
                                     '--------------------',
                                     '----------',
                                     '------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Entry_ID As EntryID,
                   Posted_By As PostedBy,
                   Entered,
                   Type,
                   Message
            FROM t_log_entries
            WHERE entry_id > _entryID AND
                  posted_by ILike 'Update%EUS%'
            ORDER BY entry_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.EntryID,
                                _previewData.PostedBy,
                                _previewData.Entered,
                                _previewData.Type,
                                _previewData.Message
                               );

            RAISE INFO '%', _infoData;
        END LOOP
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    CALL post_usage_log_entry ('update_eus_info_from_eus_imports', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.update_eus_info_from_eus_imports IS 'UpdateEUSInfoFromEUSImports';
