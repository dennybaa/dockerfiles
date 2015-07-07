# dockerfiles

## Publish

```
Usage: ./publish.sh [--no-cache --no-push --rm] [-p registry prefix path ] container container ...
   --no-cache - Do not use cache when building the image
   --no-push  - Do not publish into remote repository
   --rm       - Remove intermediate containers after a successful build

   -p         - Path to remote registry including prefix, ex: quay.io/myusername/
```

### Publish usage examples

Before using, don't forget to login into remote repository if needed (ex.  `docker login quay.io`).

1. Publish specific container:
  ```
  ./publish.sh -p quay.io/dennybaa/ droneunit-ubuntu
  ```
1. Publish all containers stored in directories under current path:
  ```
  ./publish.sh -p quay.io/dennybaa/ $(ls -d */)
  ```
1. Build specific container ignore cache without publishing it:
  ```
  ./publish.sh --no-push --no-cache -p quay.io/dennybaa/ droneunit-ubuntu
  ```
  The command above will only build and tag container as *quay.io/dennybaa/droneunit-ubuntu*, but it won't push image into remote repository quay.io.
