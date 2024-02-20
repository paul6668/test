CMD ["mvn"]
ENTRYPOINT ["/usr/local/bin/mvn-entrypoint.sh"]
ENV MAVEN_CONFIG=/root/.m2
ARG USER_HOME_DIR=/root
ARG MAVEN_VERSION=3.9.6
RUN /bin/sh -c ln -s ${MAVEN_HOME}/bin/mvn /usr/bin/mvn # buildkit
COPY /usr/share/maven/ref/settings-docker.xml /usr/share/maven/ref/settings-docker.xml # buildkit
COPY /usr/local/bin/mvn-entrypoint.sh /usr/local/bin/mvn-entrypoint.sh # buildkit
COPY /usr/share/maven /usr/share/maven # buildkit
ENV MAVEN_HOME=/usr/share/maven
RUN /bin/sh -c apt-get update && apt-get install -y ca-certificates curl git --no-install-recommends && rm -rf /var/lib/apt/lists/* # buildkit
CMD["jshell"]
ENTRYPOINT["/__cacert_entrypoint.sh"]
COPYfile:8b8864b3e02a33a579dc216fd51b28a6047bc8eeaa03045b258980fe0cf7fcb3 in /__cacert_entrypoint.sh
RUNset -eux; echo "Verifying install ..."; fileEncoding="$(echo 'System.out.println(System.getProperty("file.encoding"))' | jshell -s -)"; [ "$fileEncoding" = 'UTF-8' ]; rm -rf ~/.java; echo "javac --version"; javac --version; echo "java --version"; java --version; echo "Complete."
RUNset -eux; ARCH="$(dpkg --print-architecture)"; case "${ARCH}" in aarch64|arm64) ESUM='e184dc29a6712c1f78754ab36fb48866583665fa345324f1a79e569c064f95e9'; BINARY_URL='https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.1%2B12/OpenJDK21U-jdk_aarch64_linux_hotspot_21.0.1_12.tar.gz'; ;; amd64|i386:x86-64) ESUM='1a6fa8abda4c5caed915cfbeeb176e7fbd12eb6b222f26e290ee45808b529aa1'; BINARY_URL='https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.1%2B12/OpenJDK21U-jdk_x64_linux_hotspot_21.0.1_12.tar.gz'; ;; ppc64el|powerpc:common64) ESUM='9574828ef3d735a25404ced82e09bf20e1614f7d6403956002de9cfbfcb8638f'; BINARY_URL='https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.1%2B12/OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.1_12.tar.gz'; ;; *) echo "Unsupported arch: ${ARCH}"; exit 1; ;; esac; wget --progress=dot:giga -O /tmp/openjdk.tar.gz ${BINARY_URL}; echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; mkdir -p "$JAVA_HOME"; tar --extract --file /tmp/openjdk.tar.gz --directory "$JAVA_HOME" --strip-components 1 --no-same-owner ; rm -f /tmp/openjdk.tar.gz ${JAVA_HOME}/lib/src.zip; find "$JAVA_HOME/lib" -name '*.so' -exec dirname '{}' ';' | sort -u > /etc/ld.so.conf.d/docker-openjdk.conf; ldconfig; java -Xshare:dump;
ENVJAVA_VERSION=jdk-21.0.1+12
RUNset -eux; apt-get update; DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl wget fontconfig ca-certificates p11-kit binutils tzdata locales ; echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen; locale-gen en_US.UTF-8; rm -rf /var/lib/apt/lists/*
ENVLANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENVPATH=/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENVJAVA_HOME=/opt/java/openjdk
CMD["/bin/bash"]
ADDfile:2b3b5254f38a790d40e31cb26155609f7fc99ef7bc99eae1e0d67fa9ae605f77 in /
LABELorg.opencontainers.image.version=22.04
LABELorg.opencontainers.image.ref.name=ubuntu
ARGLAUNCHPAD_BUILD_ARCH
ARGRELEASE
