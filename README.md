# ceph-grafana
Create grafana container that contains the config required for Ceph integration

## Purpose
This repo just provides an example buildah script to generate a grafana container which holds  
- grafana
- ceph dashboards - pulled from upstream master
- vonage-status-panel plugin
- piechart plugin
- provisioning definition for the dashboards

The versions of grafana, and the plugins are defined in the script so testing can be done against a known configuration.  

## Container
The current implementation uses buildah with a CentOS (7 or 8) base image. The resulting image looks larger than it needs to be, so more work there! 

## Build Instructions
Ensure you have the following dependencies installed on your system
- buildah  
- jq
- make  (if using the Makefile)

With those dependencies in place, the recommended way to create the container(s) is via the Makefile.
```
# make                         <-- create container with dashboards from master 
# make all
# make ceph_version=octopus
# make ceph_version=nautilus
```

The older build script is also available for reference only.
```
# ./build.sh
```  

Once complete, a ```make all``` execution will provide the following containers on your system.
```
# podman images
REPOSITORY                    TAG        IMAGE ID       CREATED          SIZE
localhost/ceph/ceph-grafana   master     606fa5444fc6   14 minutes ago   497 MB
localhost/ceph-grafana        master     606fa5444fc6   14 minutes ago   497 MB
localhost/ceph-grafana        octopus    580b089c14e7   15 minutes ago   497 MB
localhost/ceph/ceph-grafana   octopus    580b089c14e7   15 minutes ago   497 MB
localhost/ceph-grafana        nautilus   3c91712dd26f   17 minutes ago   497 MB
localhost/ceph/ceph-grafana   nautilus   3c91712dd26f   17 minutes ago   497 MB
registry.centos.org/centos    8          29d8fb6c94af   30 hours ago     223 MB

```
## Usage
A container is available on [docker hub](https://hub.docker.com/r/pcuzner/ceph-grafana-el8)  
```
docker pull pcuzner/ceph-grafana-el8:latest
```
