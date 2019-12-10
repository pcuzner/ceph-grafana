# ceph-grafana
Create upstream grafana container that contains the config required for Ceph integration

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
Ensure you have buildah installed, then 
```
# ./build.sh
```  

