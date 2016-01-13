require! \moment
{Obj} = require \prelude-ls
require! \querystring
URL = require \url

# to-gmt :: String -> String
to-gmt = (local-datetime) -> 
    (moment local-datetime, 'YYYY-MM-DDTHH:mm' .utc-offset 0 .format 'YYYY-MM-DDTHH:mm:ss') + \Z

# !pure function
# update-querystring :: String -> object -> String
update-querystring = (url, patch) -->
    {query, pathname} = URL.parse url
    new-querystring = querystring.stringify do 
        ({} <<< (querystring.parse query) <<< patch)
    "#{pathname}?#{decodeURIComponent new-querystring}"

module.exports = {to-gmt, update-querystring}