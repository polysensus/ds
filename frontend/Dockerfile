
# build the contracts to get the abi
FROM playmint/foundry:v0.8.17 AS contracts
ENV FOUNDRY_SOLC_VERSION=0.8.17
ENV FOUNDRY_OFFLINE=true
WORKDIR /contracts
COPY contracts /contracts
RUN forge build

# build frontend
FROM node:18-alpine AS builder
RUN apk add --no-cache libc6-compat
WORKDIR /app
RUN apk add --update python3 make g++\
   && rm -rf /var/cache/apk/*
COPY package*.json ./
COPY frontend ./frontend
COPY docs ./docs
COPY frontend/public/ds-unity ./frontend/public/ds-unity
COPY core ./core
COPY cli ./cli
COPY --from=contracts /contracts/lib/cog/services/schema/*.graphqls ./contracts/lib/cog/services/schema/
COPY --from=contracts /contracts/out/Actions.sol/Actions.json ./contracts/out/Actions.sol/Actions.json
COPY --from=contracts /contracts/out/Zones721.sol/Zones721.json ./contracts/out/Zones721.sol/Zones721.json
COPY --from=contracts /contracts/out/Downstream.sol/DownstreamGame.json ./contracts/out/Downstream.sol/DownstreamGame.json
RUN npm config set fetch-retry-maxtimeout 300000 && \
    npm install -g npm@9 && \
    npm ci
RUN npm run build:abi -w core
RUN npm run build:graphql -w core
ENV NEXT_TELEMETRY_DISABLED 1
WORKDIR /app
RUN npm run export -w frontend

# output image
FROM caddy:2.6.4
COPY --from=builder /app/frontend/out /usr/share/caddy
COPY frontend/Caddyfile /etc/caddy/Caddyfile

