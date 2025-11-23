# Kotlin Spring Boot Backend Service

A simple HTTP backend service built with Kotlin and Spring Boot for testing Envoy Gateway and Datadog integration.

## Features

- REST API with echo endpoints
- Health check endpoint
- Prometheus metrics export
- Pod name and namespace awareness
- Actuator endpoints for monitoring

## Endpoints

- `GET /` - Root endpoint with greeting
- `GET /health` - Health check
- `GET /**` - Echo GET requests with query params
- `POST /**` - Echo POST requests with body
- `GET /actuator/prometheus` - Prometheus metrics

## Building

```bash
./gradlew build
```

## Running Locally

```bash
./gradlew bootRun
```

## Docker Build

```bash
docker build -t backend-service:latest .
```

## Environment Variables

- `POD_NAME` - Kubernetes pod name (injected by deployment)
- `NAMESPACE` - Kubernetes namespace (injected by deployment)

## Kubernetes Deployment

The service is deployed via `k8s-manifests/envoy-quickstart-sample/quickstart.yaml`
