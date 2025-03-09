FROM --platform=$BUILDPLATFORM ghcr.io/gleam-lang/gleam:v1.9.0-erlang-slim AS deps
WORKDIR /app

COPY gleam.toml manifest.toml ./
RUN gleam update

COPY ./src/ ./src/

FROM deps AS test
RUN apt update && apt install ca-certificates -y
COPY ./test/ ./test/
RUN gleam build

FROM deps AS build
RUN gleam export erlang-shipment

FROM ghcr.io/gleam-lang/gleam:v1.9.0-erlang-slim AS final
WORKDIR /app
RUN apt update && apt install ca-certificates -y
COPY --from=build /app/build/erlang-shipment .

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
