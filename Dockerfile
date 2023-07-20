FROM debian:bullseye-slim

LABEL maintainer="rizki.k@pm.me"

ARG PUID=1000
ARG SERVER_FILE

ENV USER terraria
ENV HOMEDIR "/home/${USER}"
ENV SERVERDIR "${HOMEDIR}/server"

RUN set -x \
    && apt update \
    && apt install -y curl unzip \
    && useradd -u ${PUID} -m ${USER} \
    && su ${USER} -c \
        "mkdir -p ${SERVERDIR} \
         && curl -L \
            $( \
                curl -sL https://terraria.fandom.com/wiki/Server | \
                grep 'Terraria Server [0-9.]' | \
                tail -1 | \
                grep -oP 'href="\K[^"]+' \
            ) > ${SERVERDIR}/server.zip \
         && unzip ${SERVERDIR}/server.zip -d ${SERVERDIR}"

USER ${USER}

RUN set -x \
    && cd ${SERVERDIR} \
    && cp -rfp ./$(ls -d */)/* . \
    && chmod +x ./Linux/TerrariaServer.bin.x86* \
    && mkdir -p /home/terraria/.local/share/Terraria

WORKDIR ${HOMEDIR}

