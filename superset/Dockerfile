FROM apache/superset:latest

USER root

#packages and dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    default-libmysqlclient-dev \
    unixodbc-dev \
    pkg-config \
    python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN uv pip install --python /app/.venv \
    psycopg2-binary \
    mysqlclient \
    pyodbc \
    pymssql

RUN curl -sSL -O https://packages.microsoft.com/config/debian/$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2 | cut -d '.' -f 1)/packages-microsoft-prod.deb && \
   dpkg -i packages-microsoft-prod.deb && \
   apt-get update && \
   ACCEPT_EULA=Y apt-get install -y msodbcsql17 && \
   ACCEPT_EULA=Y apt-get install -y mssql-tools

COPY config/superset_config.py /app/pythonpath/superset_config.py
COPY config/superset-init.sh /app/superset-init.sh

RUN chmod +x /app/superset-init.sh

