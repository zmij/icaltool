# nextzoommtg

This is a command line utility to get current meeting (actually in three minutes ahead) from icaltool, feed the json into python script (it's much better with handling json and regular expressions) and use applescript to pause music and open up zoom directly with needed zoom conference room.

The apple script is an example that works if you have installed `icaltool` and `extract-zoom-link` to `/usr/local/bin` directory. The python script requires `requests` module to resolve 'fancy' personal zoom links that don't have a numeric conference number, but a custom name. The script sends a get request for a redirection response.