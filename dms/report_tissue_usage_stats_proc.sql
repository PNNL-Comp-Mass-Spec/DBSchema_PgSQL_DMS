--
-- Name: report_tissue_usage_stats_proc(text, text, text, text, text, refcursor, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.report_tissue_usage_stats_proc(IN _startdate text, IN _enddate text, IN _campaignidfilterlist text DEFAULT ''::text, IN _organismidfilterlist text DEFAULT ''::text, IN _instrumentfilterlist text DEFAULT ''::text, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Generate tissue usage statistics for experiments
**
**  Arguments:
**    _startDate                Start date; if an empty string, use 2 weeks before _endDate
**    _endDate                  End date;   if an empty string, use today as end date
**                              If _instrumentFilterList is empty, filters on experiment creation date; if _instrumentFilterList is not empty, filters on dataset date
**    _campaignIDFilterList     Comma-separated list of campaign IDs
**    _organismIDFilterList     Comma separated list of organism IDs
**    _instrumentFilterList     Comma-separated list of instrument names; % and * wildcards are allowed ('*' is auto-changed to '%'); if empty, dataset stats are not returned
**    _results                  Output: cursor for retrieving production stats
**    _message                  Status message
**    _returnCode               Return code
**
**  Use this to view the data returned by the _results cursor
**  Note that this will result in an error if no matching items are found
**
**      BEGIN;
**          CALL public.report_tissue_usage_stats_proc (
**                      _startDate            => '2023-09-01',
**                      _endDate              => '2023-09-30',
**                      _campaignIDFilterList => '',
**                      _organismIDFilterList => '',
**                      _instrumentFilterList => ''
**               );
**          FETCH ALL FROM _results;
**      END;
**
**      BEGIN;
**          CALL public.report_tissue_usage_stats_proc (
**                      _startDate => '2023-09-01',
**                      _endDate   => '2023-09-30',
**                      _campaignIDFilterList => '',
**                      _organismIDFilterList => '',
**                      _instrumentFilterList => 'Exploris%,Lumos%'
**               );
**          FETCH ALL FROM _results;
**      END;
**
**  Alternatively, use an anonymous code block (though it cannot return query results; it can only store them in a table or display them with RAISE INFO)
**
**      DO
**      LANGUAGE plpgsql
**      $block$
**      DECLARE
**          _results refcursor := '_results'::refcursor;
**          _message text;
**          _returnCode text;
**          _formatSpecifier text;
**          _infoHead text;
**          _infoHeadSeparator text;
**          _currentRow record;
**          _infoData text;
**      BEGIN
**          CALL public.report_tissue_usage_stats_proc (
**                      _startDate            => '2023-09-01',
**                      _endDate              => '2023-09-30',
**                      _campaignIDFilterList => '',
**                      _organismIDFilterList => '',
**                      _instrumentFilterList => '',
**                      _results              => _results,
**                      _message              => _message,
**                      _returnCode           => _returnCode
**               );
**
**          If Exists (SELECT name FROM pg_cursors WHERE name = '_results') Then
**              RAISE INFO 'Cursor has data';
**
**              RAISE INFO '';
**
**              _formatSpecifier := '%-13s %-65s %-11s %-8s %-11s %-25s %-25s %-26s %-26s %-50s %-50s %-60s %-60s';
**
**              _infoHead := format(_formatSpecifier,
**                                  'Tissue_ID',
**                                  'Tissue',
**                                  'Experiments',
**                                  'Datasets',
**                                  'Instruments',
**                                  'Instrument_First',
**                                  'Instrument_Last',
**                                  'Dataset_or_Exp_Created_Min',
**                                  'Dataset_or_Exp_Created_Max',
**                                  'Organism_First',
**                                  'Organism_Last',
**                                  'Campaign_First',
**                                  'Campaign_Last'
**                                 );
**
**              _infoHeadSeparator := format(_formatSpecifier,
**                                           '-------------',
**                                           '-----------------------------------------------------------------',
**                                           '-----------',
**                                           '--------',
**                                           '-----------',
**                                           '-------------------------',
**                                           '-------------------------',
**                                           '--------------------------',
**                                           '--------------------------',
**                                           '--------------------------------------------------',
**                                           '--------------------------------------------------',
**                                           '------------------------------------------------------------',
**                                           '------------------------------------------------------------'
**                                          );
**
**              RAISE INFO '%', _infoHead;
**              RAISE INFO '%', _infoHeadSeparator;
**
**              WHILE true
**              LOOP
**                  FETCH NEXT FROM _results
**                  INTO _currentRow;
**
**                  If Not FOUND Then
**                      EXIT;
**                  End If;
**
**                  _infoData := format(_formatSpecifier,
**                                      _currentRow.Tissue_ID,
**                                      _currentRow.Tissue,
**                                      _currentRow.Experiments,
**                                      _currentRow.Datasets,
**                                      _currentRow.Instruments,
**                                      _currentRow.Instrument_First,
**                                      _currentRow.Instrument_Last,
**                                      _currentRow.Dataset_or_Exp_Created_Min,
**                                      _currentRow.Dataset_or_Exp_Created_Max,
**                                      _currentRow.Organism_First,
**                                      _currentRow.Organism_Last,
**                                      _currentRow.Campaign_First,
**                                      _currentRow.Campaign_Last
**                                     );
**
**                  RAISE INFO '%', _infoData;
**              END LOOP;
**          Else
**              RAISE INFO 'Cursor is not open';
**          End If;
**      END
**      $block$;
**
**  Auth:   mem
**  Date:   02/20/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN
        ---------------------------------------------------
        -- Generate tissue usage statistics
        ---------------------------------------------------

        Open _results For
            SELECT Src.Tissue_ID,
                   Src.Tissue,
                   Src.Experiments,
                   Src.Datasets,
                   Src.Instruments,
                   Src.Instrument_First,
                   Src.Instrument_Last,
                   Src.Dataset_or_Exp_Created_Min,
                   Src.Dataset_or_Exp_Created_Max,
                   Src.Organism_First,
                   Src.Organism_Last,
                   Src.Campaign_First,
                   Src.Campaign_Last
            FROM report_tissue_usage_stats(_startDate, _endDate, _campaignIDFilterList, _organismIDFilterList, _instrumentFilterList) AS Src
            ORDER BY Src.Tissue;

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

END
$_$;


ALTER PROCEDURE public.report_tissue_usage_stats_proc(IN _startdate text, IN _enddate text, IN _campaignidfilterlist text, IN _organismidfilterlist text, IN _instrumentfilterlist text, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

