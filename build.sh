#!/usr/bin/bash
set -o errexit


GRAFANA_VERSION='6.6.2-1'
PIECHART_VERSION='1.4.0'
STATUS_PANEL_VERSION='1.0.9'
DASHBOARD_DIR="monitoring/grafana/dashboards"
DASHBOARD_PROVISIONING="ceph-dashboard.yml"
IMAGE="centos:8"
VERSION="${IMAGE: -1}"
PKGMGR="dnf"

if [ "$VERSION" == '7' ]; then
    PKGMGR='yum'
fi

# Build a grafana instance - preconfigured for use within Ceph's dashboard UI

rm -f dashboards
rm -f grafana-*.rpm
rm -f *.json
rm -f ${DASHBOARD_PROVISIONING}

container=$(buildah from $IMAGE)
#mountpoint=$(buildah mount $container)

# Using upstream grafana build
wget https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.x86_64.rpm
#cp grafana-${GRAFANA_VERSION}.x86_64.rpm ${mountpoint}/tmp/.
buildah copy $container grafana-${GRAFANA_VERSION}.x86_64.rpm /tmp/.
buildah run $container ${PKGMGR} install -y --setopt install_weak_deps=false --setopt=tsflags=nodocs /tmp/grafana-${GRAFANA_VERSION}.x86_64.rpm
buildah run $container ${PKGMGR} clean all
buildah run $container rm -f /tmp/grafana*.rpm
buildah run $container grafana-cli plugins install grafana-piechart-panel ${PIECHART_VERSION}
buildah run $container grafana-cli plugins install vonage-status-panel ${STATUS_PANEL_VERSION}
buildah run $container mkdir -p /etc/grafana/dashboards/ceph-dashboard

# get contents of monitoring/dashboards directory
wget -O - https://api.github.com/repos/ceph/ceph/contents/${DASHBOARD_DIR} | jq '.[].download_url' > dashboards

# drop quotes from the list and pick out only json files
sed -i 's/\"//g' dashboards 
while read line; do
    if [[ "$line" == *.json ]]; then 
        wget $line
    fi 
done < dashboards

buildah copy $container ./*.json /etc/grafana/dashboards/ceph-dashboard

# create a dashboard provisioning file, so grafana can find them
cat > ${DASHBOARD_PROVISIONING} <<"EOF"
apiVersion: 1

providers:
- name: 'Ceph Dashboard'
  orgId: 1
  folder: 'ceph-dashboard'
  type: file
  disableDeletion: false
  updateIntervalSeconds: 3
  editable: false
  options:
    path: '/etc/grafana/dashboards/ceph-dashboard'
EOF

buildah copy $container ${DASHBOARD_PROVISIONING} /etc/grafana/provisioning/dashboards/${DASHBOARD_PROVISIONING}
#cp ${DASHBOARD_PROVISIONING} ${mountpoint}/etc/grafana/provisioning/dashboards/${DASHBOARD_PROVISIONING}

# expose tcp/3000 for grafana
buildah config --port 3000 $container

# set working dir
buildah config --workingdir /usr/share/grafana $container

# set environment overrides from the default locations in /usr/share
buildah config --env GF_PATHS_LOGS="/var/log/grafana" $container
buildah config --env GF_PATHS_PLUGINS="/var/lib/grafana/plugins" $container
buildah config --env GF_PATHS_PROVISIONING="/etc/grafana/provisioning" $container
buildah config --env GF_PATHS_DATA="/var/lib/grafana" $container

GF_CONFIG="/etc/grafana/grafana.ini"

# entrypoint
buildah config --entrypoint "grafana-server --config=${GF_CONFIG}" $container

# finalize
buildah config --label maintainer="Paul Cuzner <pcuzner@redhat.com>" $container
buildah config --label description="Ceph Grafana Container" $container
buildah config --label summary="Grafana Container configured for Ceph mgr/dashboard integration" $container
buildah commit --format docker --squash $container ceph-grafana:latest
#buildah unmount $mountpoint

