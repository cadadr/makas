# server.sh --- preview HTTP server
. scripts/config.sh
log=server.log
(cd $OUTDIR && python2 -m SimpleHTTPServer) > $log 2> $log
