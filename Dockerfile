FROM apache/nifi:2.2.0

# Copy configuration files
COPY nifi.properties /opt/nifi/nifi-current/conf/nifi.properties
COPY keystore.p12 /opt/nifi/nifi-current/conf/keystore.p12
COPY truststore.p12 /opt/nifi/nifi-current/conf/truststore.p12
COPY rootCA.pem /opt/nifi/nifi-current/conf/rootCA.pem
COPY public.pem /opt/nifi/nifi-current/conf/public.pem
COPY private.pem /opt/nifi/nifi-current/conf/private.pem
