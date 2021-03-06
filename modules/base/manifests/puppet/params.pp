class base::puppet::params {
    ## run puppet by cron and
    ## rotate puppet logs generated by cron
    ## This is in mins. Do not set this to 0 or > 60
    $interval = 30
    $crontime = fqdn_rand(60)
    # Calculate freshness interval in seconds (hence *60)
    $freshnessinterval = $interval * 60 * 6
}
