FROM openjdk:8-jdk
MAINTAINER Furcy Pin

# Update package repository
RUN apt-get update

# Install Readline Wrapper
RUN apt-get install -y rlwrap && rm -rf /var/lib/apt/lists/*

# Install sbt
ENV SBT_VERSION 0.13.15
RUN wget http://dl.bintray.com/sbt/debian/sbt-${SBT_VERSION}.deb -O /tmp/sbt.deb && \
    dpkg -i /tmp/sbt.deb && \
    rm -f /tmp/sbt.deb

# Install Hadoop
ENV HADOOP_VERSION=2.7.3
ENV HADOOP_HOME /opt/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/conf
ENV PATH $PATH:$HADOOP_HOME/bin
RUN curl -sL \
  "https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
    | gunzip \
    | tar -x -C /opt/ \
  && rm -rf $HADOOP_HOME/share/doc \
  && chown -R root:root $HADOOP_HOME \
  && mkdir -p $HADOOP_HOME/logs \
  && mkdir -p $HADOOP_CONF_DIR \
  && chmod 777 $HADOOP_CONF_DIR \
  && chmod 777 $HADOOP_HOME/logs 


# Install Hive
ENV HIVE_VERSION=2.0.1
ENV HIVE_HOME=/opt/apache-hive-$HIVE_VERSION-bin
ENV HIVE_CONF_DIR=$HIVE_HOME/conf
ENV PATH $PATH:$HIVE_HOME/bin
RUN curl -sL \
  "https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz" \
    | gunzip \
    | tar -x -C /opt/ \
  && chown -R root:root $HIVE_HOME \
  && mkdir -p $HIVE_HOME/hcatalog/var/log \
  && mkdir -p $HIVE_HOME/var/log \
  && mkdir -p /data/hive/ \
  && mkdir -p $HIVE_CONF_DIR \
  && chmod 777 $HIVE_HOME/hcatalog/var/log \
  && chmod 777 $HIVE_HOME/var/log

# Install S3 jars for Hive
RUN ln -s $HADOOP_HOME/share/hadoop/tools/lib/aws-java-sdk-1.7.4.jar $HIVE_HOME/lib/.
RUN ln -s $HADOOP_HOME/share/hadoop/tools/lib/hadoop-aws-2.7.3.jar $HIVE_HOME/lib/.

# Install Spark
ENV SPARK_VERSION=2.3.1
ENV SPARK_HOME=/opt/spark-$SPARK_VERSION-bin-hadoop2.7
ENV SPARK_CONF_DIR=$SPARK_HOME/conf
ENV PATH $PATH:$SPARK_HOME/bin
RUN curl -sL \
  "https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz" \
    | gunzip \
    | tar -x -C /opt/ \
  && chown -R root:root $SPARK_HOME \
  && mkdir -p /data/spark/ \
  && mkdir -p $SPARK_HOME/logs \
  && mkdir -p $SPARK_CONF_DIR \
  && chmod 777 $SPARK_HOME/logs

# Install S3 jars for Spark
RUN ln -s $HADOOP_HOME/share/hadoop/tools/lib/aws-java-sdk-1.7.4.jar $SPARK_HOME/jars/.
RUN ln -s $HADOOP_HOME/share/hadoop/tools/lib/hadoop-aws-2.7.3.jar $SPARK_HOME/jars/.

# Install mssql-jdbc driver for Spark
ENV MSSQL_JDBC_VERSION=6.4.0.jre8
RUN wget http://central.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/$MSSQL_JDBC_VERSION/mssql-jdbc-$MSSQL_JDBC_VERSION.jar -O $SPARK_HOME/jars/mssql-jdbc-$MSSQL_JDBC_VERSION.jar


# Configure
ADD files/hive-site.xml $HIVE_CONF_DIR/
ADD files/hive-site.xml $SPARK_CONF_DIR/
ADD files/start.sh /
ADD files/init.sh /
ADD files/beeline.sh /

EXPOSE 22
EXPOSE 4040
EXPOSE 9083
EXPOSE 10000

ENTRYPOINT ["/beeline.sh"]



