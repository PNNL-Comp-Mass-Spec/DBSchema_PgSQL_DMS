--
CREATE OR REPLACE PROCEDURE public.update_bionet_host_status
(
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the Last_Online column in T_Bionet_Hosts
**      by looking for datasets associated with any instrument associated with the given host
**
**  Auth:   mem
**  Date:   12/02/2015 mem - Initial version
**          09/11/2019 mem - Exclude tracking datasets when finding the most recent dataset for each instrument
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    -----------------------------------------
    -- Create some temporary tables
    -----------------------------------------

    CREATE TEMP TABLE Tmp_Hosts (
        Host text not null,
        Instrument text not null,
        MostRecentDataset timestamp not null
    )

    CREATE UNIQUE INDEX IX_Tmp_Hosts ON Tmp_Hosts (Host, Instrument);

    -----------------------------------------
    -- Find the most recent dataset for each instrument associated with an entry in t_bionet_hosts
    -----------------------------------------

    INSERT INTO Tmp_Hosts( host,
                            instrument,
                            MostRecentDataset )
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
           SPath.machine_name = BionetHosts.host || '.bionet') AND
          (SPath.storage_path_function LIKE '%inbox%') AND
          (NOT (DS.created IS NULL)) AND
          DS.dataset_type_ID <> 100          -- Exclude tracking datasets
    GROUP BY BionetHosts.host, Inst.instrument;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        -- Preview the new info
        --
        SELECT Target.Host,
               Target.Last_Online,
               Src.MostRecentDataset,
               CASE WHEN Src.MostRecentDataset > Coalesce(Target.Last_Online, make_date(1970, 1, 1))
               THEN Src.MostRecentDataset
               ELSE Null
               END AS New_Last_Online
        FROM t_bionet_hosts Target
             INNER JOIN ( SELECT host,
                                 MAX(MostRecentDataset) AS MostRecentDataset
                          FROM Tmp_Hosts
                          GROUP BY host ) Src
               ON Target.host = Src.host;

    Else

        -- Update Last_Online
        --
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

    End If;

    DROP TABLE Tmp_Hosts;
END
$$;

COMMENT ON PROCEDURE public.update_bionet_host_status IS 'UpdateBionetHostStatus';
