--
-- Name: get_requested_run_name_code(text, timestamp without time zone, text, integer, text, integer, timestamp without time zone, integer, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_requested_run_name_code(_requestname text, _requestcreated timestamp without time zone, _requesterusername text, _batchid integer, _batchname text, _batchgroupid integer, _batchcreated timestamp without time zone, _datasettypeid integer, _separationtype text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generates the Name Code string for a given requested run
**      This string is used when grouping requested runs for run planning purposes
**
**      The request name code will be based on the request name, date, requester username, dataset type, and separation type if _batchID = 0
**      Otherwise, if _batchID is non-zero, it is based on the batch name, date, batch ID, dataset type, and separation type
**
**      Examples:
**          GCM_20210825_R_POIR043_18_GC
**          MoT_20210706_B_8050_13_LC-Acetylome
**
**  Return value: string
**
**  Auth:   mem
**  Date:   08/05/2010
**          08/10/2010 mem - Added _datasetTypeID and _separationType
**                         - Increased size of return string to varchar(64)
**          08/26/2021 mem - Use Batch ID instead of username
**          06/22/2022 mem - Ported to PostgreSQL
**          02/08/2023 mem - Switch from PRN to username
**          02/21/2023 mem - Add parameter _batchGroupID
**          05/22/2023 mem - Capitalize reserved word
**          05/30/2023 mem - Use format() for string concatenation
**
*****************************************************/
BEGIN
    RETURN CASE WHEN Coalesce(_batchID, 0) = 0
                THEN format('%s_%s_R_%s_%s_%s',
                            SUBSTRING(_requestName, 1, 3),
                            to_char(_requestCreated, 'yyyymmdd'),
                            _requesterUsername,
                            Coalesce(_datasetTypeID, 0),
                            Coalesce(_separationType, ''))
                ELSE format('%s%s_%s_B_%s_%s_%s',
                            CASE WHEN Coalesce(_batchGroupID, 0) > 0
                                 THEN format('%s_', _batchGroupID)
                                 ELSE ''
                            END,
                            SUBSTRING(_batchName, 1, 3),
                            to_char(_batchCreated, 'yyyymmdd'),
                            _batchID,
                            Coalesce(_datasetTypeID, 0),
                            Coalesce(_separationType, ''))
           END;
END
$$;


ALTER FUNCTION public.get_requested_run_name_code(_requestname text, _requestcreated timestamp without time zone, _requesterusername text, _batchid integer, _batchname text, _batchgroupid integer, _batchcreated timestamp without time zone, _datasettypeid integer, _separationtype text) OWNER TO d3l243;

--
-- Name: FUNCTION get_requested_run_name_code(_requestname text, _requestcreated timestamp without time zone, _requesterusername text, _batchid integer, _batchname text, _batchgroupid integer, _batchcreated timestamp without time zone, _datasettypeid integer, _separationtype text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_requested_run_name_code(_requestname text, _requestcreated timestamp without time zone, _requesterusername text, _batchid integer, _batchname text, _batchgroupid integer, _batchcreated timestamp without time zone, _datasettypeid integer, _separationtype text) IS 'GetRequestedRunNameCode';

