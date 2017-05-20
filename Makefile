STACK_NAME = s3strm-ftp-importer
STACK_TEMPLATE = file://./cfn.yml
ACTION := $(shell ./bin/cloudformation_action $(STACK_NAME))
UPLOAD ?= true

DOWNLOAD_FINDER_KEY = $(shell make -C lambdas/download_finder/src lambda_key)

export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION
export AWS_ACCESS_KEY_ID

.PHONY = deploy upload docker_image test

deploy: upload
	aws cloudformation ${ACTION}-stack                                      \
	  --stack-name "${STACK_NAME}"                                          \
	  --template-body "${STACK_TEMPLATE}"                                   \
	  --parameters                                                          \
	    ParameterKey=DownloadFinderCodeKey,ParameterValue=${DOWNLOAD_FINDER_KEY} \
	  --capabilities CAPABILITY_IAM                                         \
	  2>&1
	@aws cloudformation wait stack-${ACTION}-complete \
	  --stack-name ${STACK_NAME}

upload:
ifeq ($(UPLOAD),true)
	@make -C lambdas/download_finder/src upload
endif
