Create an init.d file (for example, 'crowd.init.d') inside your {CROWD_INSTALL} directory:

#!/bin/sh -e
# Crowd startup script
#chkconfig: 2345 80 05
#description: Crowd

# Define some variables
# Name of app ( JIRA, Confluence, etc )
APP=crowd
# Name of the user to run as
USER=crowd
# Location of Crowd install directory
CATALINA_HOME=/usr/local/crowd/atlassian-crowd-3.5.1
# Location of Java JDK
export JAVA_HOME=/usr/lib/jvm/adoptopenjdk-8-hotspot-amd64

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
