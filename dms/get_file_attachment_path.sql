--
-- Name: get_file_attachment_path(public.citext, public.citext); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_file_attachment_path(_entitytype public.citext, _entityid public.citext) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**    Returns storage path for file attachment for the given DMS tracking entity
**
**    _spreadFolder is the folder spreader, used to group items by date to avoid folders with 1000's of subdirectories
**
**    The following entities have _spreadFolder based on year and month, e.g. 2016_2
**        Campaign
**        Dataset
**        Experiment
**        Sample_Prep_Request
**        Sample_Submission
**
**    The following entities have _spreadFolder based on year alone, e.g. 2016
**        Experiment_Group
**        Instrument_Config
**        Instrument_Config_History
**        Instrument_Operation
**        Instrument_Operation_History
**        LC_Cart_Config  (deprecated in 2017)
**        LC_Cart_Config_History
**
**    All other DMS entities have _spreadFolder in the form spread/ItemID, e.g. spread/195
**        LC_Cart_Configuration
**        Material_Container
**        Operations_Tasks
**        Osm_Package
**
**  Return value:
**    File attachment path, examples:
**        sample_prep_request/2017_1/4574
**        instrument_config/2015/5775
**        osm_package/spread/195
**
**  Arguments:
**    _entityID   Entity ID, though for Campaign, Dataset, Experiment, and Sample Prep Request supports both entity ID or entity name
**
**  Auth:   grk
**  Date:   04/16/2011
**          04/26/2011 grk - added sample prep request
**          08/23/2011 grk - added experiment_group
**          11/15/2011 grk - added sample_submission
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          02/24/2017 mem - Update capitalization and add comments
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          06/21/2022 mem - Ported to PostgreSQL
**          12/15/2022 mem - Use extract(year from _variable) and extract(month from) to extract the year and month from timestamps
**          05/19/2023 mem - Use format() to combine strings
**
*****************************************************/
DECLARE
    _spreadFolder text := 'spread';
    _created timestamp := '1/1/1900';
    _campaignID int;
    _experimentID int;
    _datasetID int;
    _samplePrepID int;
    _idValue int;
BEGIN

    If _entityType = 'campaign' Then
        _campaignID := try_cast(_entityID, true, 0);

        If _campaignID Is Null Then
            SELECT campaign_id::text, created
            INTO _entityID, _created
            FROM t_campaign
            WHERE campaign = _entityID;

            If FOUND Then
                _spreadFolder := format('%s_%s', extract(year from _created), extract(month from _created));
            End If;
        Else
            SELECT created
            INTO _created
            FROM t_campaign
            WHERE campaign_id = _campaignID;

            If FOUND Then
                _spreadFolder := format('%s_%s', extract(year from _created), extract(month from _created));
            End If;
        End If;
    End If;

    If _entityType = 'experiment' Then
        _experimentID := try_cast(_entityID, true, 0);

        If _experimentID Is Null Then
            SELECT exp_id::text, created
            INTO _entityID, _created
            FROM t_experiments
            WHERE experiment = _entityID;

            If FOUND Then
                _spreadFolder := format('%s_%s', extract(year from _created), extract(month from _created));
            End If;
        Else
            SELECT created
            INTO _created
            FROM t_experiments
            WHERE exp_id = _experimentID;

            If FOUND Then
                _spreadFolder := format('%s_%s', extract(year from _created), extract(month from _created));
            End If;
        End If;
    End If;

    If _entityType = 'dataset' Then
        _datasetID := try_cast(_entityID, true, 0);

        If _datasetID Is Null Then
            SELECT dataset_id::text, created
            INTO _entityID, _created
            FROM t_dataset
            WHERE dataset = _entityID;

            If FOUND Then
                _spreadFolder := format('%s_%s', extract(year from _created), extract(month from _created));
            End If;
        Else
            SELECT created
            INTO _created
            FROM t_dataset
            WHERE dataset_id = _datasetID;

            If FOUND Then
                _spreadFolder := format('%s_%s', extract(year from _created), extract(month from _created));
            End If;
        End If;
    End If;

    If _entityType = 'sample_prep_request' Then
        _samplePrepID := try_cast(_entityID, true, 0);

        If _samplePrepID Is Null Then
            SELECT prep_request_id::text, created
            INTO _entityID, _created
            FROM t_sample_prep_request
            WHERE request_name = _idValue;

            If FOUND Then
                _spreadFolder := format('%s_%s', extract(year from _created), extract(month from _created));
            End If;
        Else
            SELECT created
            INTO _created
            FROM t_sample_prep_request
            WHERE prep_request_id = _samplePrepID;

            If FOUND Then
                _spreadFolder := format('%s_%s', extract(year from _created), extract(month from _created));
            End If;
        End If;
    End If;

    If _entityType = 'instrument_operation_history' Then
        _entityType := 'instrument_operation';
        _idValue := try_cast(_entityID, true, 0);

        If Not _idValue Is Null Then
            SELECT entered
            INTO _created
            FROM t_instrument_operation_history
            WHERE entry_id = _idValue;

            If FOUND Then
                _spreadFolder := extract(year from _created)::text;
            End If;
        End If;
    End If;

    If _entityType = 'instrument_config_history' Then
        _entityType := 'instrument_config';
        _idValue := try_cast(_entityID, true, 0);

        If Not _idValue Is Null Then
            SELECT entered
            INTO _created
            FROM t_instrument_config_history
            WHERE entry_id = _idValue;

            If FOUND Then
                _spreadFolder := extract(year from _created)::text;
            End If;
        End If;
    End If;

    If _entityType = 'lc_cart_config_history' Then
        _entityType := 'lc_cart_config';
        _idValue := try_cast(_entityID, true, 0);

        If Not _idValue Is Null Then
            SELECT entered
            INTO _created
            FROM t_lc_cart_config_history
            WHERE entry_id = _idValue;

            If FOUND Then
                _spreadFolder := extract(year from _created)::text;
            End If;
        End If;
    End If;

    If _entityType = 'experiment_group' Then
        _idValue := try_cast(_entityID, true, 0);

        If Not _idValue Is Null Then
            SELECT created
            INTO _created
            FROM t_experiment_groups
            WHERE group_id = _idValue;

            If FOUND Then
                _spreadFolder := extract(year from _created)::text;
            End If;
        End If;
    End If;

    If _entityType = 'sample_submission' Then
        _idValue := try_cast(_entityID, true, 0);

        If Not _idValue Is Null Then
            SELECT created
            INTO _created
            FROM t_sample_submission
            WHERE submission_id = _idValue;

            If FOUND Then
                _spreadFolder := format('%s_%s', extract(year from _created), extract(month from _created));
            End If;
        End If;
    End If;

    If _spreadFolder = 'spread' Then
        RETURN format('%s/%s', _entityType, Coalesce(_entityID, ''));
    Else
        RETURN format('%s/%s/%s', _entityType, _spreadFolder, Coalesce(_entityID, ''));
    End If;
END
$$;


ALTER FUNCTION public.get_file_attachment_path(_entitytype public.citext, _entityid public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION get_file_attachment_path(_entitytype public.citext, _entityid public.citext); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_file_attachment_path(_entitytype public.citext, _entityid public.citext) IS 'GetFileAttachmentPath';

