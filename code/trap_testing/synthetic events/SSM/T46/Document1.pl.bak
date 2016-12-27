
        if(match($community, "REMAX"))
        {
                $ssm_community = "REMAX"
        }
        else if(nmatch($community, "ESX"))
        {
                $ssm_community = lookup(@NodeAlias, ESX_Swiss_Table)
        }
        else
        {
                $ssm_community = "UNIX"
        }

#       20080523        Change by Chris Janes of Abilitec       TD 4851
        switch($ssm_community)
        {
                 case "ESX":
                        $CommunityClass = 5017181
                case "ESX_SWISS":
                        $CommunityClass = 5917181
                default:
                        $CommunityClass = 123000
        }



$1 = logMonXControlLogFile - Absolute path to the log file being monitored. This field can include the wildcards '*' or '?' to monitor multiple files. For example: to monitor all files is /var/log you would enter '/var/log/*'.
$2 = logMonXHistoryLine - A line from the log file that matched the filter in this entry's associated control row.
$3 = logMonXHistoryLevel - Log entry level, if known.
$4 = logMonXControlDescription - A description of the control row.
