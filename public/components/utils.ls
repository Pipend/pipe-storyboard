require! \moment
{filter, Obj, obj-to-pairs, pairs-to-obj} = require \prelude-ls
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
        {} <<< (querystring.parse query) <<< (patch
            |> obj-to-pairs
            |> filter -> (typeof it.1) != \undefined
            |> pairs-to-obj
        )
    "#{pathname}?#{decodeURIComponent new-querystring}"

module.exports = {to-gmt, update-querystring}