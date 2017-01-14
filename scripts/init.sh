#!/bin/bash

ECODE=0
while true ; do

  # Execute and load the variable definition file
  #
  echo "Load definitions"
  . /vagrant/scripts/definitions.sh
  [ $? -ne 0 ] && { ECODE=10; break; }

  # check whether the installation is flagged ready or not
  #
  [ -f ~/install.status ] && { echo "Already installed"; break; }

  # create a download folder if it is not alread there
  #
  echo "Create download dir"
  [ ! -d ${SETUP_PKGS} ] && { mkdir -p ${SETUP_PKGS};  [ $? -ne 0 ] && { ECODE=14; break; } }

  # install missing system packages
  #
  echo "Installing system packages"
  yum -y install wget nc
  [ $? -ne 0 ] && { ECODE=12; break; }

  # assign setup scripts the execute rights
  #
  echo "chmod some scripts"
  chmod u+x ${SETUP_SCRIPTS}/*.sh
  [ $? -ne 0 ] && { ECODE=9; break; }

  # download a JDK if necessary
  #
  if [ ! -f ${SETUP_PKGS}/${JDK_RPM} ]; then
      echo "Downloading JDK"

      wget -O ${SETUP_PKGS}/${JDK_RPM} --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "${JDK_SRCURL}" -o ~/java_wget.log
      [ $? -ne 0 ] && { ECODE=20; break; }
      cat ~/java_wget.log && rm ~/java_wget.log
  else
      echo "Skip downloading JDK"
  fi

  # install the JDK
  #
  echo "Install JDK"
  rpm -ivh ${SETUP_PKGS}/${JDK_RPM}
  [ $? -ne 0 ] && { ECODE=22; break; }


  # download kafka if not already there
  #
  if [ ! -f  ${SETUP_PKGS}/${KAFKA_NAME}.tgz ]; then
    echo "Downloading kafka...$KAFKA_VERSION"

    wget -O "${SETUP_PKGS}/${KAFKA_NAME}.tgz" ${KAFKA_SRCURL} -o ~/kafka_wget.log
    [ $? -ne 0 ] && { ECODE=16; break; }

    cat ~/kafka_wget.log && rm ~/kafka_wget.log
  else
    echo "Skip downloading kafka...${KAFKA_VERSION}"
  fi

  # Download zookeeper if not already there
  #
  if [ ! -f  ${SETUP_PKGS}/${ZOOKEEPER_NAME}.tar.gz ]; then
    echo "Downloading zookeeper...$ZOOKEEPER_VERSION"

    wget -O "${SETUP_PKGS}/${ZOOKEEPER_NAME}.tar.gz" ${ZOOKEEPER_SRCURL} -o  ~/zookeeper_wget.log
    [ $? -ne 0 ] && { ECODE=17; break; }

    cat ~/zookeeper_wget.log && rm ~/zookeeper_wget.log
  else
    echo "Skip downloading zookeeper...${ZOOKEEPER_VERSION}"
  fi

  #
  # Install kafka software
  #
  echo "Prepare kafka user, folders & software"
  groupadd kafka && useradd -d ${KAFKA_HOME} -m -g kafka kafka && echo ${KAFKA_PWD}  | passwd --stdin kafka
  [ $? -ne 0 ] && { ECODE=30; break; }

  tar xvfz ${SETUP_PKGS}/${KAFKA_NAME}.tgz -C ${KAFKA_HOME} --strip-components=1
  [ $? -ne 0 ] && { ECODE=32; break; }

  mkdir /tmp/kafka-logs && chown kafka:kafka -R /tmp/kafka-logs

  chown kafka:kafka -R ${KAFKA_HOME}
  [ $? -ne 0 ] && { ECODE=34; break; }

  echo "PATH=~/bin:${PATH}; export PATH" >> ${KAFKA_HOME}/.bash_profile
  echo ". ${SETUP_SCRIPTS}/definitions.sh" >> ${KAFKA_HOME}/.bash_profile

  #
  # Install zookeeper software
  #
  echo "Prepare zookeeper user, folders & software"

  useradd -d ${ZOOKEEPER_HOME} -m -g kafka zookeeper && echo ${ZOOKEEPER_PWD}  | passwd --stdin zookeeper
  [ $? -ne 0 ] && { ECODE=40; break; }

  tar xvfz ${SETUP_PKGS}/${ZOOKEEPER_NAME}.tar.gz -C ${ZOOKEEPER_HOME} --strip-components=1
  [ $? -ne 0 ] && { ECODE=42; break; }

  echo "PATH=~/bin:${PATH}; export PATH" >> ${ZOOKEEPER_HOME}/.bash_profile
  echo ". ${SETUP_SCRIPTS}/definitions.sh" >> ${ZOOKEEPER_HOME}/.bash_profile

  mkdir /tmp/zookeeper && chown zookeeper:kafka -R /tmp/zookeeper

  chown zookeeper:kafka -R /opt/zookeeper
  [ $? -ne 0 ] && { ECODE=44; break; }

  # mark the software to be installed
  echo "Install" > ~/install.status

  # definitly end
  #
  break
done

case ${ECODE} in
  0)  MSG="ok" ;;
  8)  MSG="Error: shutdown IPTables failed" ;;
  9)  MSG="Error: chmod scripts failed" ;;
  10) MSG="Error: loading definitions failed" ;;
  12) MSG="Error: installation of system packages failed" ;;
  14) MSG="Error: mkdir download folder failed" ;;
  16) MSG="Error: wget kafka failed" ;;
  17) MSG="Error: wget zookeeper failed" ;;
  20) MSG="Error: wget JDK failed" ;;
  22) MSG="Error: JDK install failed" ;;
  30) MSG="Error: creation of kafka user failed" ;;
  32) MSG="Error: untar kafka software failed" ;;
  34) MSG="Error: chown kafka software failed" ;;
  40) MSG="Error: creation of zookeeper user failed" ;;
  42) MSG="Error: untar zookeeper software failed" ;;
  43) MSG="Error: zoo.cfg missing" ;;
  44) MSG="Error: chown zookeeper software failed" ;;
  *)  MSG="Error: unknown reason" ;;
esac

echo ${MSG}
exit ${ECODE}
