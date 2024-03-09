--
-- Name: update_bionet_host_status(boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_bionet_host_status(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update last_online in t_bionet_hosts by looking for datasets associated with any instrument associated with the given host
**
**  Arguments:
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   12/02/2015 mem - Initial version
**          09/11/2019 mem - Exclude tracking datasets when finding the most recent dataset for each instrument
**          02/28/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _updateCount int;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    -----------------------------------------
    -- Create some temporary tables
    -----------------------------------------

    CREATE TEMP TABLE Tmp_Hosts (
        Host text NOT NULL,
        Instrument text NOT NULL,
        MostRecentDataset timestamp NOT NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_Hosts ON Tmp_Hosts (Host, Instrument);

    -----------------------------------------
    -- Find the most recent dataset for each instrument associated with an entry in t_bionet_hosts
    -----------------------------------------

    INSERT INTO Tmp_Hosts (
        Host,
        Instrument,
        MostRecentDataset
    )
    SELECT BionetHosts.host,
           Inst.instrument,
           MAX(DS.created) AS MostRecentDataset
    FROM t_storage_path SPath
         INNER JOIN t_instrument_name Inst
           ON SPath.storage_path_id = Inst.source_path_id
         INNER JOIN t_dataset DS
           ON Inst.instrument_id = DS.instrument_id
         CROSS JOIN t_bionet_hosts BionetHosts
    WHERE (SPath.machine_name = BionetHosts.host OR
           SPath.machine_name = format('%s.bionet', BionetHosts.host)) AND
          SPath.storage_path_function LIKE '%inbox%' AND
          NOT (DS.created IS NULL) AND
          DS.dataset_type_ID <> 100          -- Exclude tracking datasets
    GROUP BY BionetHosts.host, Inst.instrument;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-20s %-17s %-20s %-16s';

        _infoHead := format(_formatSpecifier,
                            'Host',
                            'Last_Online',
                            'Most_Recent_Dataset',
                            'New_Last_Online'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------------------',
                                     '-----------------',
                                     '--------------------',
                                     '----------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Target.Host,
                   public.timestamp_text(Target.Last_Online) AS Last_Online,
                   public.timestamp_text(Src.MostRecentDataset) AS Most_Recent_Dataset,
                   CASE WHEN Src.MostRecentDataset > Coalesce(Target.Last_Online, make_date(1970, 1, 1))
                        THEN public.timestamp_text(Src.MostRecentDataset)
                        ELSE ''
                   END AS New_Last_Online
            FROM t_bionet_hosts Target
                 INNER JOIN ( SELECT host,
                                     MAX(MostRecentDataset) AS MostRecentDataset
                              FROM Tmp_Hosts
                              GROUP BY host ) Src
                   ON Target.host = Src.host
            ORDER BY Target.Host
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Host,
                                Left(_previewData.Last_Online, 16),
                                Left(_previewData.Most_Recent_Dataset, 16),
                                Left(_previewData.New_Last_Online, 16)
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_Hosts;
        RETURN;
    End If;

    -- Update last_online

    UPDATE t_bionet_hosts Target
    SET last_online = CASE WHEN Src.MostRecentDataset > Coalesce(Target.last_online, make_date(1970, 1, 1))
                      THEN Src.MostRecentDataset
                      ELSE Target.Last_Online
                      END
    FROM ( SELECT Host,
                  MAX(MostRecentDataset) AS MostRecentDataset
           FROM Tmp_Hosts
           GROUP BY Host ) Src
    WHERE Target.Host = Src.Host;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    _message := format('Updated %s %s in t_bionet_hosts', _updateCount, public.check_plural(_updateCount, 'host', 'hosts'));
    RAISE INFO '%', _message;

    DROP TABLE Tmp_Hosts;
END
$$;


ALTER PROCEDURE public.update_bionet_host_status(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_bionet_host_status(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_bionet_host_status(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateBionetHostStatus';

