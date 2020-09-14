#!/usr/bin/env bash

##
# xmlstarlet el -a sm6125-r0-portotmo-driveonly.xml | sort -u
# xmlstarlet el sm6125-r0-portotmo-driveonly.xml | sort -u

function test_parse_xml() {
    :
    # xmlstarlet sel -T -t -m /manifest/project -v "concat(@name,' ')" -n sm6125-r0-portotmo-driveonly.xml | sort -u
    # xmlstarlet sel -T -t -m /manifest/remote  -v "concat(@fetch,'')" -n sm6125-r0-portotmo-driveonly.xml | awk -F: '{print $NF}' | sort -u
}