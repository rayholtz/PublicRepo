#!/bin/sh -e
# copied from https://confluence.atlassian.com/crowd034/setting-crowd-to-run-automatically-and-use-an-unprivileged-system-user-on-unix-974361572.html

# Crowd startup script
#chkconfig: 2345 80 05
#description: Crowd

# Define some variables
# Name of app ( JIRA, Confluence, etc )
APP=crowd
# Name of the user to run as
USER=crowd
# Location of Crowd install directory
CATALINA_HOME=/atl/crowd-install/atlassian-crowd-3.4.3
# Location of Java JDK
export JAVA_HOME=/usr/java/jdk1.8.0_251-amd64

case "$1" in
  # Start command
  start)
    echo "Starting $APP"
    /bin/su -m $USER -c "$CATALINA_HOME/start_crowd.sh &> /dev/null"
    ;;
  # Stop command
  stop)
    echo "Stopping $APP"
    /bin/su -m $USER -c "$CATALINA_HOME/stop_crowd.sh &> /dev/null"
    echo "$APP stopped successfully"
    ;;
   # Restart command
   restart)
        $0 stop
        sleep 5
        $0 start
        ;;
  *)
    echo "Usage: /etc/init.d/$APP {start|restart|stop}"
    exit 1
    ;;
esac

exit 0
