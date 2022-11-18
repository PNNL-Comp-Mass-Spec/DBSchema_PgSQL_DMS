--
-- Name: reconcile_inst_name_table_to_storage_assignments(); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.reconcile_inst_name_table_to_storage_assignments()
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**     This procedures updates the assigned source and storage
**     path columns in the instrument name table (t_instrument_name)
**     according to the assignments given in the storage path table
**     (t_storage_path)
**
**  Auth:   grk
**  Date:   01/26/2001
**          11/16/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int;
BEGIN

    ---------------------------------------------------
    -- Set source path assignment (inbox)
    ---------------------------------------------------

    -- Each instrument should only have one row in t_storage_path with storage_path_function = 'inbox', but manual data entry sometimes introduces duplicates
    -- Use Row_Number() to select the newest row
    --
    UPDATE t_instrument_name
    SET source_path_id = RankQ.storage_path_id
    FROM ( SELECT SPath.instrument, SPath.storage_path_id, Row_Number() Over (Partition By Instrument Order By storage_path_id Desc) as RowNum
           FROM t_storage_path SPath
           WHERE SPath.storage_path_function = 'inbox') RankQ
    WHERE T_Instrument_Name.instrument = RankQ.instrument AND
          RankQ.RowNum = 1 AND
          source_path_id <> RankQ.storage_path_id;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount > 0 Then
        RAISE INFO 'Updated source_path_id  for % % based on "inbox" rows in t_storage_path',
                    _myRowCount, public.check_plural(_myRowCount, 'instrument', 'instruments');
    Else
        RAISE INFO 'Source_path_id values are already up-to-date in t_instrument_name';
    End If;

    ---------------------------------------------------
    -- Set storage path assignment
    ---------------------------------------------------

    -- Each instrument should only have one row in t_storage_path with storage_path_function = 'raw-storage', but manual data entry sometimes introduces duplicates
    -- Use Row_Number() to select the newest row
    --
    UPDATE t_instrument_name
    SET storage_path_ID = RankQ.storage_path_id
    FROM ( SELECT SPath.instrument, SPath.storage_path_id, Row_Number() Over (Partition By Instrument Order By storage_path_id Desc) as RowNum
           FROM t_storage_path SPath
           WHERE SPath.storage_path_function = 'raw-storage') RankQ
    WHERE T_Instrument_Name.instrument = RankQ.instrument AND
          RankQ.RowNum = 1 AND
          t_instrument_name.storage_path_ID <> RankQ.storage_path_id;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount > 0 Then
        RAISE INFO 'Updated storage_path_ID for % % based on "raw-storage" rows in t_storage_path',
                    _myRowCount, public.check_plural(_myRowCount, 'instrument', 'instruments');
    Else
        RAISE INFO 'storage_path_ID values are already up-to-date in t_instrument_name';
    End If;

END
$$;


ALTER PROCEDURE public.reconcile_inst_name_table_to_storage_assignments() OWNER TO d3l243;

--
-- Name: PROCEDURE reconcile_inst_name_table_to_storage_assignments(); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.reconcile_inst_name_table_to_storage_assignments() IS 'ReconcileInstNameTableToStorageAssignments';

