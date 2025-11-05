FROM grafana/alloy:latest

# Copy configuration file
COPY config.alloy /etc/alloy/config.alloy

# Expose HTTP port for log ingestion
EXPOSE 3100

# Run Alloy with the config
ENTRYPOINT ["/bin/alloy", "run", "/etc/alloy/config.alloy"]

