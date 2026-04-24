# --- Stage 1: Build Stage ---
FROM sbtscala/scala-sbt:eclipse-temurin-alpine-17.0.10_7_1.9.9_2.13.13 AS builder

WORKDIR /app

# Copy all source files
COPY . .

# RUN THE ACTUAL COMPILATION (This usually takes 5-10 minutes)
RUN export FAUNADB_RELEASE=true && sbt service/assembly

# --- Stage 2: Runtime Stage ---
FROM eclipse-temurin:17-jre-alpine

WORKDIR /faunadb
RUN apk add --no-cache bash
RUN mkdir -p /faunadb/bin /faunadb/lib /faunadb/data

# 1. COPY THE CONFIG FILE (Add this line)
COPY faunadb.yml /faunadb/faunadb.yml

# 2. Copy the JAR and scripts (as before)
COPY --from=builder /app/service/target/scala-2.13/faunadb.jar /faunadb/lib/faunadb.jar
COPY --from=builder /app/service/src/main/scripts/faunadb /faunadb/bin/
COPY --from=builder /app/service/src/main/scripts/faunadb-admin /faunadb/bin/
COPY --from=builder /app/service/src/main/scripts/faunadb-backup-s3-upload /faunadb/bin/

RUN chmod +x /faunadb/bin/*
ENV PATH="/faunadb/bin:${PATH}"

EXPOSE 8443 8084

ENTRYPOINT ["faunadb"]
