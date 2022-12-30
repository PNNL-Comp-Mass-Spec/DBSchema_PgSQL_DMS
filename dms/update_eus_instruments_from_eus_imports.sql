--
-- Name: update_eus_instruments_from_eus_imports(text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_eus_instruments_from_eus_imports(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates information in T_EMSL_Instruments from EUS
**
**      Obtains data from nexus-prod-db.emsl.pnl.gov using the postgres_fdw foreign data wrapper
**
**      Use the following commands to define the foreign data wrapper:
**
**          CREATE EXTENSION IF NOT EXISTS postgres_fdw;
**          DROP SERVER IF EXISTS NEXUS_fdw CASCADE;
**
**          CREATE SERVER NEXUS_fdw FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'nexus-prod-db.emsl.pnl.gov', dbname 'nexus_db_production_20210226', port '5432');
**          SELECT * FROM pg_catalog.pg_user;
**
**          CREATE USER MAPPING FOR d3l243 SERVER NEXUS_fdw OPTIONS (user 'dmsreader', password 'dms....');
**          SELECT * FROM pg_user_mapping;
**
**          GRANT USAGE ON FOREIGN SERVER NEXUS_fdw TO d3l243;
**
**          CREATE SCHEMA IF NOT EXISTS eus;
**          IMPORT FOREIGN SCHEMA proteomics_views FROM SERVER NEXUS_fdw INTO eus;
**
**  Auth:   grk
**  Date:   06/29/2011 grk - Initial version
**          07/19/2011 grk - Last_Affected
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          03/27/2012 grk - Added EUS_Active_Sw and EUS_Primary_Instrument
**          05/12/2021 mem - Use new NEXUS-based views
**          12/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _countOld int := 0;
    _countNew int := 0;
    _mergeCount int := 0;
    _mergeInsertCount int := 0;
    _mergeUpdateCount int := 0;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    BEGIN
        -- Count the number of rows before the merge
        --
        SELECT COUNT(*)
        INTO _countOld
        FROM t_emsl_instruments;

        ---------------------------------------------------
        -- Use a MERGE Statement to synchronize
        -- t_emsl_instruments with V_NEXUS_Import_Instruments
        ---------------------------------------------------

        MERGE INTO t_emsl_instruments AS Target
        USING
            ( SELECT    instrument_id AS Instrument_ID,
                        instrument_name AS Instrument_Name,
                        eus_display_name AS Display_Name,
                        available_hours AS Available_Hours,
                        CASE WHEN active_sw THEN '1' ELSE '0' END AS Active_Sw,
                        CASE WHEN primary_instrument THEN '1' ELSE '0' END AS Primary_Instrument
              FROM      V_NEXUS_Import_Instruments Source
            ) AS Source ( Instrument_ID, Instrument_Name, Display_Name,
                          Available_Hours, Active_Sw, Primary_Instrument )
        ON ( target.eus_instrument_id = source.Instrument_ID )
        WHEN MATCHED
            THEN UPDATE SET
                eus_instrument_name = Instrument_Name,
                eus_display_name = Display_Name,
                eus_available_hours = Available_Hours,
                last_affected = CURRENT_TIMESTAMP,
                eus_active_sw = Active_Sw,
                eus_primary_instrument = Primary_Instrument
        WHEN NOT MATCHED
            THEN INSERT  (
                  eus_instrument_id,
                  eus_instrument_name,
                  eus_display_name,
                  eus_available_hours,
                  eus_active_sw,
                  eus_primary_instrument
                ) VALUES
                ( source.Instrument_ID,
                  source.Instrument_Name,
                  source.Display_Name,
                  source.Available_Hours,
                  source.Active_Sw,
                  source.Primary_Instrument
                )
        ;

        GET DIAGNOSTICS _mergeCount = ROW_COUNT;

        -- Count the number of rows after the merge
        --
        SELECT COUNT(*)
        INTO _countNew
        FROM t_emsl_instruments;

        If _mergeCount > 0 Then
            _mergeInsertCount := _countNew - _countOld;
            _mergeUpdateCount := _mergeCount - _mergeInsertCount;

            _message := format('Updated t_emsl_instruments: %s added; %s updated', _mergeInsertCount, _mergeUpdateCount);

            Call post_log_entry ('Normal', _message, 'UpdateEUSInstrumentsFromEUSImports');

            _message := '';
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

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Call post_usage_log_entry ('UpdateEUSInstrumentsFromEUSImports', '');
END
$$;


ALTER PROCEDURE public.update_eus_instruments_from_eus_imports(INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_eus_instruments_from_eus_imports(INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_eus_instruments_from_eus_imports(INOUT _message text, INOUT _returncode text) IS 'UpdateEUSInstrumentsFromEUSImports';

