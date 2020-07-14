#!/bin/bash

# copied from https://confluence.atlassian.com/crowd034/setting-crowd-to-run-automatically-and-use-an-unprivileged-system-user-on-unix-974361572.html
CROWD_USER="crowd"
CROWD_GROUP="crowd"
INSTALL_BASE="/atl/crowd-install/atlassian-crowd-3.4.3"
CROWD_HOME="/atl/crowd-home"
sudo chgrp ${CROWD_GROUP} ${INSTALL_BASE}/{*.sh,apache-tomcat/bin/*.sh}
sudo chmod g+x ${INSTALL_BASE}/{*.sh,apache-tomcat/bin/*.sh}
sudo chown -R ${CROWD_USER} ${CROWD_HOME} ${INSTALL_BASE}/apache-tomcat/{logs,work,temp}
sudo touch -a ${INSTALL_BASE}/atlassian-crowd-openid-server.log
sudo chown -R ${CROWD_USER} ${INSTALL_BASE}/{database,atlassian-crowd-openid-server.log}
