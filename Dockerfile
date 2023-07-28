FROM ubuntu:22.04

# install ca-certificates to be able to pull https traffic to...
# install git, unzip, wget to install vanilla server, tModLoader
# hadolint ignore=DL3008
RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    git \
    unzip \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# update certs
RUN update-ca-certificates

# install dotnet, required for start-tModLoaderServer.sh
# see https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#2204
ENV DEBIAN_FRONTEND=noninteractive

# hadolint ignore=DL3008
RUN wget --progress=dot:giga https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install --no-install-recommends -y apt-transport-https \
    && apt-get update \
    && apt-get install --no-install-recommends -y dotnet-sdk-6.0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install mono
# see https://www.mono-project.com/download/stable/#download-lin
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install --no-install-recommends -y gnupg ca-certificates \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list \
    && apt-get update \
    && apt-get install  --no-install-recommends -y mono-complete \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install steam, steamcmd
# Insert Steam prompt answers
RUN echo steam steam/question select "I AGREE" | debconf-set-selections \
    && echo steam steam/license note '' | debconf-set-selections

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends  software-properties-common \
    && add-apt-repository multiverse \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends steam \
    && echo "I AGREE" | apt-get install -y --no-install-recommends lib32gcc-s1 steamcmd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/games:${PATH}"

# non-root user
ARG USERNAME=terraria
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# hadolint ignore=DL3008
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install --no-install-recommends -y sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# grant non-root user access to run steamcmd
# RUN chown ${USER_GID}:${USER_UID} /usr/games/steamcmd
# switch to non-root user
USER $USERNAME
WORKDIR /home/${USERNAME}

# see https://github.com/ldericher/tmodloader-docker/blob/e24ae0950544a27fe4dc383058218766d0ecf16f/Dockerfile
# get vanilla server \
ARG SERVER_FILE_URL=https://terraria.org/api/download/pc-dedicated-server/terraria-server-1449.zip
RUN wget --progress=dot:giga ${SERVER_FILE_URL} \
    && unzip terraria-server-*.zip \
    && rm terraria-server-*.zip \
    && cp --verbose -a 1436/. . \
    && rm -rf 1436 Mac Windows \
    && mv Linux Terraria

# clone tModLoader
ARG TMOD_LOADER_GIT_TAG=v2022.09.47.75
RUN wget --progress=dot:giga "https://github.com/tModLoader/tModLoader/releases/download/${TMOD_LOADER_GIT_TAG}/tModLoader.zip" \
    && unzip tModLoader.zip -d tModLoader \
    && rm tModLoader.zip \
    && chmod u+x tModLoader/start-tModLoader* \
    && chmod u+x tModLoader/LaunchUtils/ScriptCaller.sh \
    && sudo chown ${USER_GID}:${USER_UID} /usr/games/steamcmd \
    && sudo chown ${USER_GID}:${USER_UID} /usr/games/steam \
    && sudo chmod u+x /usr/games/steamcmd \
    && sudo chmod u+x /usr/games/steam

# Update SteamCMD and verify latest version
RUN steamcmd +quit

RUN curl -O https://raw.githubusercontent.com/tModLoader/tModLoader/1.4.4/patches/tModLoader/Terraria/release_extras/DedicatedServerUtils/manage-tModLoaderServer.sh \
    && chmod u+x manage-tModLoaderServer.sh \
    && ./manage-tModLoaderServer.sh -i -g --no-mods \
    && chmod u+x $HOME/tModLoader/start-tModLoaderServer.sh

# Download entrypoint script
RUN curl -O https://raw.githubusercontent.com/tModLoader/tModLoader/1.4.4/patches/tModLoader/Terraria/release_extras/DedicatedServerUtils/Docker/Launch.sh \
    && chmod u+x Launch.sh

EXPOSE 7777

ENTRYPOINT [ "/bin/bash", "-c", "./Launch.sh" ]
