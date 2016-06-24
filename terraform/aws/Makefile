SHELL := $(SHELL) -e
VARS_FILE  := aws.tfvars
PLAN_FILE  := aws.tfplan
STATE_FILE := aws.tfstate

all: plan apply

plan:
	terraform get -update
	terraform plan -var-file ${VARS_FILE} -out ${PLAN_FILE}

apply:
	terraform apply -var-file ${VARS_FILE}

destroy:
	terraform plan -destroy -var-file ${VARS_FILE} -out ${PLAN_FILE}
	terraform apply ${PLAN_FILE}

clean:
	rm -f ${PLAN_FILE}
	rm -f ${STATE_FILE}

.PHONY: all plan apply destroy clean
