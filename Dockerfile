name: Docker Build and Push

on:
  push:
    branches: [ "main" ]
    tags: [ "v*.*.*" ]
  workflow_dispatch:
    inputs:
      modsec_version:
        description: 'ModSecurity Version'     
        required: true
        default: '3.0.11'
      crs_version:
        description: 'CRS Version'
        required: true
        default: '3.3.4'

env:
  IMAGE_NAME: your-dockerhub-username/your-image-name

jobs:
  build-and-push:
    name: Build and Push to Docker Hub
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout Code
      uses: actions/checkout@v4

    - name: Docker Setup
      uses: docker/setup-buildx-action@v3

    - name: Login to Docker Hub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}

    - name: Build and Push Docker Image
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: linux/amd64
        build-args: |
          MODSEC3_VERSION=${{ github.event.inputs.modsec_version || '3.0.11' }}
          CRS_VERSION=${{ github.event.inputs.crs_version || '3.3.4' }}
        tags: |
          ${{ env.IMAGE_NAME }}:latest
          ${{ env.IMAGE_NAME }}:${{ github.sha }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
        push: true
