# NPCP bias correction configuration
#
# The required user defined variables are:
# - VAR (options: tasmin tasmax pr)
# - TASK (options: historical xvalidation projection)
# - RCM_NAME (options: BOM-BARPA-R UQ-DES-CCAM-2105 CSIRO-CCAM-2203 GCM)
# - GCM_NAME (options: ECMWF-ERA5 CSIRO-ACCESS-ESM1-5 EC-Earth-Consortium-EC-Earth3 NCAR-CESM2)

# Example usage:
#   make [target] [-Bn] CONFIG=npcp/config_npcp.mk VAR=pr TASK=projection RCM_NAME=BOM-BARPA-R GCM_NAME=CSIRO-ACCESS-ESM1-5
#

check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

## Method options
METHOD=ecdfm
NQUANTILES=100
GROUPING=--time_grouping monthly
INTERP=linear
OUTPUT_GRID=af
COMPRESSION=--compress
PROJECT_ID=npcp
OUTPUT_TIME_UNITS=--output_time_units days_since_1850-01-01

## Variable options
$(call check_defined, VAR)

ifeq (${VAR}, pr)
SCALING=multiplicative
SSR=--ssr
UNITS="mm day-1"
MAX_AF=--max_af 5
AF_SMOOTHING=${INTERP}-maxaf5
else
SCALING=additive
UNITS=C
AF_SMOOTHING=${INTERP}
endif
METHOD_DESCRIPTION=ecdfm-${SCALING}-monthly-q${NQUANTILES}

OUTPUT_VAR=${VAR}
HIST_VAR=${VAR}
REF_VAR=${VAR}
TARGET_VAR=${VAR}
OUTPUT_UNITS=${UNITS}
HIST_UNITS=${UNITS}
REF_UNITS=${UNITS}
TARGET_UNITS=${UNITS}

## Model options
$(call check_defined, GCM_NAME)

ONE_GCM_FILE=False
ifeq (${GCM_NAME}, ECMWF-ERA5)
GCM_RUN=r1i1p1f1
EXPERIMENT=evaluation
else ifeq (${GCM_NAME}, CSIRO-ACCESS-ESM1-5)
GCM_RUN=r6i1p1f1
EXPERIMENT=ssp370
ifeq (${RCM_NAME}, GCM)
ONE_GCM_FILE=True
endif
else ifeq (${GCM_NAME}, EC-Earth-Consortium-EC-Earth3)
GCM_RUN=r1i1p1f1
EXPERIMENT=ssp370
ifeq (${RCM_NAME}, GCM)
ONE_GCM_FILE=True
endif
else ifeq (${GCM_NAME}, NCAR-CESM2)
GCM_RUN=r11i1p1f1
EXPERIMENT=ssp370
ifeq (${RCM_NAME}, GCM)
ONE_GCM_FILE=True
endif
endif
OBS_DATASET=AGCD
RCM_VERSION=v1

## Input data
$(call check_defined, TASK)
$(call check_defined, HIST_VAR)
$(call check_defined, REF_VAR)
$(call check_defined, TARGET_VAR)
$(call check_defined, RCM_NAME)
$(call check_defined, OBS_DATASET)

HIST_PATH=/g/data/ia39/npcp/data/${HIST_VAR}/${GCM_NAME}/${RCM_NAME}/raw/task-reference
REF_PATH=/g/data/ia39/npcp/data/${REF_VAR}/observations/${OBS_DATASET}/raw/task-reference
TARGET_PATH=/g/data/ia39/npcp/data/${TARGET_VAR}/${GCM_NAME}/${RCM_NAME}/raw/task-reference
ifeq (${TASK}, projection)
HIST_START=1980
HIST_END=2019
REF_START=1980
REF_END=2019
TARGET_START=2060
TARGET_END=2099
ifeq (${ONE_GCM_FILE}, False)
HIST_DATA := $(sort $(wildcard ${HIST_PATH}/${HIST_VAR}*day_19[8,9]*.nc) $(wildcard ${HIST_PATH}/${HIST_VAR}*day_20[0,1]*.nc))
TARGET_DATA := $(sort $(wildcard ${TARGET_PATH}/${TARGET_VAR}*day_20[6,7,8,9]*.nc))
endif
REF_DATA := $(sort $(wildcard ${REF_PATH}/${REF_VAR}*day_19[8,9]*.nc) $(wildcard ${REF_PATH}/${REF_VAR}*day_20[0,1]*.nc))
else ifeq (${TASK}, historical)
HIST_START=1980
HIST_END=2019
REF_START=1980
REF_END=2019
TARGET_START=1980
TARGET_END=2019
ifeq (${ONE_GCM_FILE}, False)
HIST_DATA := $(sort $(wildcard ${HIST_PATH}/${HIST_VAR}*day_19[8,9]*.nc) $(wildcard ${HIST_PATH}/${HIST_VAR}*day_20[0,1]*.nc))
TARGET_DATA := $(sort $(wildcard ${TARGET_PATH}/${TARGET_VAR}*day_19[8,9]*.nc) $(wildcard ${TARGET_PATH}/${TARGET_VAR}*day_20[0,1]*.nc))
endif
REF_DATA := $(sort $(wildcard ${REF_PATH}/${REF_VAR}*day_19[8,9]*.nc) $(wildcard ${REF_PATH}/${REF_VAR}*day_20[0,1]*.nc))
else ifeq (${TASK}, xvalidation)
ifeq (${GCM_NAME}, ECMWF-ERA5)
HIST_START=1980
HIST_END=1999
REF_START=1980
REF_END=1999
TARGET_START=2000
TARGET_END=2019
ifeq (${ONE_GCM_FILE}, False)
HIST_DATA := $(sort $(wildcard ${HIST_PATH}/${HIST_VAR}*day_19[8,9]*.nc))
TARGET_DATA := $(sort $(wildcard ${TARGET_PATH}/${TARGET_VAR}*day_20[0,1]*.nc))
endif
REF_DATA := $(sort $(wildcard ${REF_PATH}/${REF_VAR}*day_19[8,9]*.nc))
else
HIST_START=1960
HIST_END=1989
REF_START=1960
REF_END=1989
TARGET_START=1990
TARGET_END=2019
ifeq (${ONE_GCM_FILE}, False)
HIST_DATA := $(sort $(wildcard ${HIST_PATH}/${HIST_VAR}*day_19[6,7,8]*.nc))
TARGET_DATA := $(sort $(wildcard ${TARGET_PATH}/${TARGET_VAR}*day_199*.nc) $(wildcard ${TARGET_PATH}/${TARGET_VAR}*day_20[0,1]*.nc))
endif
REF_DATA := $(sort $(wildcard ${REF_PATH}/${REF_VAR}*day_19[6,7,8]*.nc))
endif
endif

ifeq (${ONE_GCM_FILE}, True)
HIST_DATA := $(wildcard ${HIST_PATH}/${HIST_VAR}*.nc)
TARGET_DATA := $(wildcard ${TARGET_PATH}/${TARGET_VAR}*.nc)
endif

TRAINING_DATES=${HIST_START}0101-${HIST_END}1231
TARGET_DATES=${TARGET_START}0101-${TARGET_END}1231

## Output data
$(call check_defined, TASK)
$(call check_defined, REF_VAR)
$(call check_defined, RCM_NAME)
$(call check_defined, OBS_DATASET)
$(call check_defined, METHOD)
$(call check_defined, SCALING)
$(call check_defined, INTERP)
$(call check_defined, NQUANTILES)
$(call check_defined, EXPERIMENT)
$(call check_defined, TRAINING_DATES)
$(call check_defined, TARGET_DATES)
$(call check_defined, GCM_RUN)
$(call check_defined, RCM_VERSION)

OUTDIR=/g/data/ia39/npcp/data/${HIST_VAR}/${GCM_NAME}/${RCM_NAME}/${METHOD}/task-${TASK}

OUTPUT_AF_DIR=${OUTDIR}
AF_FILE=${OUTPUT_VAR}-${METHOD_DESCRIPTION}-quantile-adjustment-factors_${OBS_DATASET}_NPCP-20i_${GCM_NAME}_${EXPERIMENT}_${GCM_RUN}_${RCM_NAME}_${RCM_VERSION}_day_${TRAINING_DATES}.nc
AF_PATH=${OUTPUT_AF_DIR}/${AF_FILE}

OUTPUT_QQ_DIR=${OUTDIR}
QQ_BASE=${OUTPUT_VAR}_NPCP-20i_${GCM_NAME}_${EXPERIMENT}_${GCM_RUN}_${RCM_NAME}_${RCM_VERSION}_day_${TARGET_DATES}_${METHOD_DESCRIPTION}-${AF_SMOOTHING}-${OBS_DATASET}-${TRAINING_DATES}
QQ_PATH=${OUTPUT_QQ_DIR}/${QQ_BASE}.nc

METADATA_PATH=${OUTPUT_QQ_DIR}/${QQ_BASE}.yaml
METADATA_OPTIONS= --method ${METHOD} --scaling ${SCALING} --gcm ${GCM_NAME} --rcm ${RCM_NAME} --hist_tbounds ${HIST_START}-${HIST_END} --ref_tbounds ${REF_START}-${REF_END} --target_tbounds ${TARGET_START}-${TARGET_END}

OUTPUT_VALIDATION_DIR=${OUTDIR}
VALIDATION_NOTEBOOK=${OUTPUT_VALIDATION_DIR}/${QQ_BASE}.ipynb
FINAL_QQ_PATH=${QQ_PATH}

