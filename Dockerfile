# STEP 1: Build the frontend
FROM node:21-slim as fe-build

ENV NODE_ENV=production
ENV VITE_API_URL=localhost:3000

WORKDIR /frontend

COPY ./backend/graph/schema.graphqls ../backend/graph/
COPY frontend/ .

# Install dependencies including devDependencies for codegen
RUN yarn install --frozen-lockfile --production=false
RUN ls -la /frontend
RUN yarn build

# STEP 2: Build the backend
FROM golang:1.22-alpine as be-build
ENV CGO_ENABLED=1
RUN apk add --no-cache gcc musl-dev

WORKDIR /backend

COPY backend/ .

RUN go mod download
RUN go build -ldflags='-extldflags "-static"' -o /app

# STEP 3: Build the final image
FROM alpine:3.14

# Copy the built backend and frontend artifacts
COPY --from=be-build /app /app
COPY --from=fe-build /frontend/dist /fe

# Install sqlite3
RUN apk add --no-cache sqlite

# Expose the necessary port (assuming your app runs on port 3000)
EXPOSE 3000

# Start the application
CMD ["/app"]

