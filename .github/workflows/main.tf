name: notes-app-ci

on:
  push:
    branches:
      - sandbox
      - dev
      - stage
      - main
  pull_request:
    types: closed

jobs:
  if_merged: 
    runs-on: ubuntu-latest
    if: github.event.pull_request.merged == true
    steps:
      - run: |
          echo The PR was merged to ${{ github.event.pull_request.base.ref }}

  npm-build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Use Node.js
        uses: actions/setup-node@v2
        with: 
          node-version: "14.x" # Use appropriate Node.js version here

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Run build
        run: npm run build --if-present

  docker-build:
    runs-on: ubuntu-latest
    if: ${{ always() && github.event.pull_request.merged == true && contains(join(needs.*.result, ','), 'success') && (github.event.pull_request.base.ref == 'dev' || github.event.pull_request.base.ref == 'stage' || github.event.pull_request.base.ref == 'main') }}
    needs: [if_merged]
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Docker meta
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: sivatheja2013/github-notes-app
          tags: |
            type=ref,event=pr
            type=ref,ref=${{ github.ref }}
            type=sha,ref=${{ github.sha }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
