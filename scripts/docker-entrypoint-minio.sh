#!/bin/bash
set -e

echo "=== MinIO Restaurant Service ==="

echo "Starting MinIO server..."
minio server /data --console-address ":9090" &
MINIO_PID=$!

sleep 3

echo "Waiting for MinIO to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:9000/minio/health/live > /dev/null 2>&1; then
        echo "MinIO is ready!"
        break
    fi

    if [ $i -eq 30 ]; then
        echo "ERROR: MinIO failed to start"
        exit 1
    fi

    echo "MinIO not ready yet, waiting... ($i/30)"
    sleep 2
done

echo "Configuring MinIO client..."
mc alias set local http://localhost:9000 ${MINIO_ROOT_USER:-minioadmin} ${MINIO_ROOT_PASSWORD:-minioadmin} --insecure

echo "Creating bucket 'images'..."
mc mb local/images --ignore-existing
mc anonymous set public local/images

echo "Uploading restaurant photos..."
SOURCE_DIR="/images/restaurants"

if [ -d "$SOURCE_DIR" ]; then
    echo "Found photos in: $SOURCE_DIR"

    for photo in "$SOURCE_DIR"/*.jpg "$SOURCE_DIR"/*.png "$SOURCE_DIR"/*.jpeg; do
        if [ -f "$photo" ]; then
            filename=$(basename "$photo")
            echo "Uploading: $filename"
            mc cp --insecure "$photo" local/images/
        fi
    done

    echo "Photos uploaded to MinIO"

fi

echo "Uploading dishes photos..."
SOURCE_DIR="/images/dishes"

if [ -d "$SOURCE_DIR" ]; then
    echo "Found photos in: $SOURCE_DIR"

    for photo in "$SOURCE_DIR"/*.jpg "$SOURCE_DIR"/*.png "$SOURCE_DIR"/*.jpeg; do
        if [ -f "$photo" ]; then
            filename=$(basename "$photo")
            echo "Uploading: $filename"
            mc cp --insecure "$photo" local/images/
        fi
    done

    echo "Photos uploaded to MinIO"

fi

echo "Bucket contents:"
mc ls local/images

echo ""
echo "========================================"
echo "MinIO is running!"
echo "Console: http://localhost:9090"
echo "API: http://localhost:9000"
echo "Bucket: images"
echo "========================================"

wait $MINIO_PID