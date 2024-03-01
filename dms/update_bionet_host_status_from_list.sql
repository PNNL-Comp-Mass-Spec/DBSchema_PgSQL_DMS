--
-- Name: update_bionet_host_status_from_list(text, boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_bionet_host_status_from_list(IN _hostnames text, IN _addmissinghosts boolean DEFAULT false, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update last_online in t_bionet_hosts for the computers in _hostNames
**
**  Arguments:
**    _hostNames        Comma-separated list of computer names; optionally include IP address with each host name using the format Host@IP
**    _addMissingHosts  If true, add missing hosts
**    _infoOnly         When true, preview updates
**    _message          Status message; when _infoOnly is true, will contain a vertical bar delimited list of host names to add or update
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   12/03/2015 mem - Initial version
**          12/04/2015 mem - Now auto-removing ".bionet"
**                         - Add support for including IP addresses, for example ltq_orb_3_192.168.30.78
**          03/17/2017 mem - Pass this procedure's name to Parse_Delimited_List
**          05/09/2023 mem - Add arguments _message and _returnCode
**                         - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/11/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_list for a comma-separated list
**
*****************************************************/
DECLARE
    _hostCount int;
    _updateCount int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN
        -----------------------------------------
        -- Validate the inputs
        -----------------------------------------

        _hostNames       := Trim(Coalesce(_hostNames, ''));
        _addMissingHosts := Coalesce(_addMissingHosts, false);
        _infoOnly        := Coalesce(_infoOnly, false);

        -----------------------------------------
        -- Create a temporary table
        -----------------------------------------

        CREATE TEMP TABLE Tmp_Hosts (
            Host citext NOT NULL,        -- Could have Host and IP, encoded as Host@IP
            IP text NULL,
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
        );

        CREATE INDEX IX_Tmp_Hosts ON Tmp_Hosts (Host);

        -----------------------------------------
        -- Parse the list of host names (or Host and IP combos)
        -----------------------------------------

        INSERT INTO Tmp_Hosts (Host)
        SELECT DISTINCT Value
        FROM public.parse_delimited_list(_hostNames);
        --
        GET DIAGNOSTICS _hostCount = ROW_COUNT;

        -- Split out IP address

        UPDATE Tmp_Hosts
        SET Host = Substring(FilterQ.HostAndIP, 1, AtSignLoc - 1),
            IP   = Substring(FilterQ.HostAndIP, AtSignLoc + 1, 16)
        FROM ( SELECT Entry_ID,
                      Host AS HostAndIP,
                      Position('@' In Host) AS AtSignLoc
               FROM Tmp_Hosts
               WHERE Host SIMILAR TO '%@[0-9]%' ) FilterQ
        WHERE FilterQ.Entry_ID = Tmp_Hosts.Entry_ID;

        -- Remove suffix .bionet if present

        UPDATE Tmp_Hosts
        SET Host = Replace(Host, '.bionet', '')
        WHERE Host LIKE '%.bionet';

        If _infoOnly Then
            -----------------------------------------
            -- Preview the new info
            -----------------------------------------

            RAISE INFO '';

            _formatSpecifier := '%-20s %-15s %-35s %-20s %-20s %-15s';

            _infoHead := format(_formatSpecifier,
                                'Host',
                                'IP',
                                'Warning',
                                'Last_Online',
                                'New_Last_Online',
                                'Last_IP'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------------------',
                                         '---------------',
                                         '-----------------------------------',
                                         '--------------------',
                                         '--------------------',
                                         '---------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            If _addMissingHosts Then
                _message := 'Hosts to add or update';
            Else
                _message := 'Hosts to update';
            End If;

            FOR _previewData IN
                SELECT Src.Host,
                       Src.IP,
                       CASE
                           WHEN Target.Host IS NULL AND
                                Not _addMissingHosts THEN 'Host not found; will be skipped'
                           WHEN Target.Host IS NULL AND
                                _addMissingHosts THEN 'Host not found; will be added'
                           ELSE ''
                       END AS Warning,
                       Target.Last_Online::timestamp(0),
                       CASE
                           WHEN Target.Host IS NULL AND
                                Not _addMissingHosts THEN NULL
                           ELSE CURRENT_TIMESTAMP::timestamp(0)
                       END AS New_Last_Online,
                       Target.ip AS Last_IP
                FROM Tmp_Hosts Src
                     LEFT OUTER JOIN t_bionet_hosts Target
                       ON Target.host = Src.host
                ORDER BY Src.host
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Host,
                                    _previewData.IP,
                                    _previewData.Warning,
                                    _previewData.Last_Online,
                                    _previewData.New_Last_Online,
                                    _previewData.Last_IP
                                   );

                RAISE INFO '%', _infoData;

                _message := format('%s | %s', _message, _previewData.Host);

                If _previewData.Warning <> '' Then
                    _message := format('%s (%s)', _message, Lower(_previewData.Warning));
                End If;

            END LOOP;

            DROP TABLE Tmp_Hosts;
            RETURN;

        End If;

        -----------------------------------------
        -- Update Last_Online for existing hosts
        -----------------------------------------

        UPDATE t_bionet_hosts target
        SET last_online = CURRENT_TIMESTAMP,
            ip = Coalesce(Src.ip, Target.ip)
        FROM Tmp_Hosts Src
        WHERE Target.host = Src.host;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount < _hostCount And _addMissingHosts Then

            RAISE INFO 'Adding missing hosts';

            INSERT INTO t_bionet_hosts( host,
                                        ip,
                                        entered,
                                        last_online )
            SELECT Src.host,
                   Src.ip,
                   CURRENT_TIMESTAMP,
                   CURRENT_TIMESTAMP
            FROM Tmp_Hosts Src
                 LEFT OUTER JOIN t_bionet_hosts Target
                   ON Target.host = Src.host
            WHERE Target.host IS NULL;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_Hosts;
END
$$;


ALTER PROCEDURE public.update_bionet_host_status_from_list(IN _hostnames text, IN _addmissinghosts boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_bionet_host_status_from_list(IN _hostnames text, IN _addmissinghosts boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_bionet_host_status_from_list(IN _hostnames text, IN _addmissinghosts boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateBionetHostStatusFromList';

