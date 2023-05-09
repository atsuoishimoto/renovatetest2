FROM python:3.11.0-slim-bullseye

RUN mkdir -p /usr/src/app && mkdir /log

WORKDIR /usr/src/app

ENV PYTHONUNBUFFERED 1

COPY pyproject.toml /usr/src/app/
COPY poetry.lock /usr/src/app/

RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libmariadb-dev && \
    buildDeps="curl make gcc g++ libc-dev" && \
    apt-get install -y --no-install-recommends $buildDeps && \
    curl -sSL https://install.python-poetry.org | POETRY_HOME=/opt/poetry python - && \
    ln -s /opt/poetry/bin/poetry /usr/local/bin/poetry && \
    poetry config virtualenvs.create false && \
    poetry install --no-root --no-dev && \
    apt-get purge -y --auto-remove \
        -o APT::AutoRemove::RecommendsImportant=false \
        $buildDeps && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* /var/tmp/* /root/.cache/*

COPY . /usr/src/app

RUN groupadd -g 999 appuser && \
    useradd -r -u 999 -g appuser appuser && \
    chown -R appuser:appuser /usr/src/app /log
USER appuser

RUN python banner_api/manage.py collectstatic --noinput

EXPOSE 8000

CMD ["uwsgi", "uwsgi.ini"]
