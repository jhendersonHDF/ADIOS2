#!/bin/bash --login

if [ -x /opt/cmake/bin/ctest ]
then
  CTEST=/opt/cmake/bin/ctest
else
  CTEST=ctest
fi

if [ -d /opt/hdf5/1.10.4 ]
then
  export PATH=/opt/hdf5/1.10.4/bin:$PATH
  export LD_LIBRARY_PATH=/opt/hdf5/1.10.4/lib:$LD_LIBRARY_PATH
fi

export CI_SITE_NAME="Azure Pipelines"
export CI_BUILD_NAME="pr${SYSTEM_PULLREQUEST_PULLREQUESTNUMBER}_${SYSTEM_PULLREQUEST_SOURCEBRANCH}_${BUILD_BUILDID}_${CONTAINERRESOURCE}"
export CI_ROOT_DIR="${PIPELINE_WORKSPACE}"
export CI_SOURCE_DIR="${BUILD_SOURCESDIRECTORY}"
export CI_BIN_DIR="${BUILD_BINARIESDIRECTORY}/${CONTAINERRESOURCE}"
export CI_COMMIT=$(echo "${BUILD_SOURCEVERSIONMESSAGE}" | awk '{print $2}')


STEP=$1
CTEST_SCRIPT=scripts/ci/cmake/ci-${CONTAINERRESOURCE}.cmake

# Update and Test steps enable an extra step
CTEST_STEP_ARGS=""
case ${STEP} in
  update) CTEST_STEP_ARGS="${CTEST_STEP_ARGS} -Ddashboard_do_checkout=ON" ;;
  test) CTEST_STEP_ARGS="${CTEST_STEP_ARGS} -Ddashboard_do_end=ON" ;;
esac
CTEST_STEP_ARGS="${CTEST_STEP_ARGS} -Ddashboard_do_${STEP}=ON"

# Workaround to quiet some warnings from OpenMPI
export OMPI_MCA_btl_base_warn_component_unused=0
export OMPI_MCA_btl_vader_single_copy_mechanism=none

# Enable overscription in OpenMPI
export OMPI_MCA_rmaps_base_oversubscribe=1
export OMPI_MCA_hwloc_base_binding_policy=none

echo "**********Env Begin**********"
env | sort
echo "**********Env End************"

echo "**********CTest Begin**********"
${CTEST} --version
echo ${CTEST} -VV -S ${CTEST_SCRIPT} -Ddashboard_full=OFF ${CTEST_STEP_ARGS}
${CTEST} -VV -S ${CTEST_SCRIPT} -Ddashboard_full=OFF ${CTEST_STEP_ARGS}
RET=$?
echo "**********CTest End************"
exit ${RET}