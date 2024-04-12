--
-- Name: get_experiment_plex_members(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_experiment_plex_members(_plexexperimentid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
        Builds delimited list of experiment plex members for a given experiment plex
**
**  Return value: list delimited with vertical bars and colons
**
**  Auth:   mem
**  Date:   11/09/2018 mem
**          06/21/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _headerRow text := '!Headers!Tag:Exp_ID:Experiment:Channel Type:Comment';
    _list text;
    _result text;
BEGIN
    SELECT string_agg(LookupQ.PlexMemberInfo, '|' ORDER BY LookupQ.channel)
    INTO _list
    FROM ( SELECT PlexMembers.channel,
                  format('%s:%s:%s:%s:%s',
                          Coalesce(ReporterIons.tag_name, PlexMembers.channel::text),
                          PlexMembers.exp_id,
                          ChannelExperiment.experiment,
                          ChannelType.channel_type_name,
                          Coalesce(PlexMembers.comment, '')) AS PlexMemberInfo
           FROM t_experiment_plex_members PlexMembers
                INNER JOIN t_experiments ChannelExperiment
                  ON PlexMembers.exp_id = ChannelExperiment.exp_id
                INNER JOIN t_experiment_plex_channel_type_name ChannelType
                  ON PlexMembers.channel_type_id = ChannelType.channel_type_id
                INNER JOIN t_experiments E
                  ON PlexMembers.plex_exp_id = E.exp_id
                LEFT OUTER JOIN t_sample_labelling_reporter_ions ReporterIons
                  ON PlexMembers.channel = ReporterIons.channel AND
                     E.labelling = ReporterIons.label
           WHERE PlexMembers.plex_exp_id = _plexExperimentID
           ) LookupQ;

    If Coalesce(_list, '') = '' Then
        _result := _headerRow;
    Else
        _result = format('%s|%s', _headerRow, _list);
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_experiment_plex_members(_plexexperimentid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_experiment_plex_members(_plexexperimentid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_experiment_plex_members(_plexexperimentid integer) IS 'GetExperimentPlexMembers';

