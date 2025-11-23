#!/bin/bash
set -e

echo "Building Kotlin Spring Boot Backend using Docker..."

# Configuration
REGISTRY="${DOCKER_REGISTRY:-docker.io/yourusername}"
IMAGE_NAME="backend-service"
IMAGE_TAG="${IMAGE_TAG:-1.0.0}"
FULL_IMAGE="$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"

echo "Building Docker image: $FULL_IMAGE"

# Build the Docker image (this will compile the Kotlin code inside the container)
docker build -t $FULL_IMAGE .

echo "✅ Build completed successfully!"
echo "Image: $FULL_IMAGE"
echo ""
echo "Next steps:"
echo "1. Push to registry: docker push $FULL_IMAGE"
echo "2. Update k8s-manifests/envoy-quickstart-sample/quickstart.yaml with image: $FULL_IMAGE"
echo "3. Deploy: kubectl apply -f ../k8s-manifests/envoy-quickstart-sample/quickstart.yaml"
