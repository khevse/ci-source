.DEFAULT_GOAL=all

LOCAL_BIN:=$(CURDIR)/bin
LINTER_BIN:=${LOCAL_BIN}/golangci-lint

.PHONY:all
all: lint go-test

.PHONY: publish
publish: GIT_MESSAGE?=
publish: GIT_TOKEN?=
publish: GIT_USER?=
publish: GIT_EMAIL?=
publish: GIT_BRANCH?=main
publish: GIT_REF_TYPE?=
publish: GIT_REF_NAME?=
publish: TARGET_REPO_NAME:=ci-target
publish: TARGET_REPO:=github.com/${GIT_USER}/${TARGET_REPO_NAME}
publish: TEMP_DIR:=$(shell mktemp -d)
publish:
ifndef ${GIT_TOKEN}
	$(eval $@_GIT_TOKEN=$(shell echo ${API_TOKEN_GITHUB}))
else
	$(eval $@_GIT_TOKEN:=${GIT_TOKEN})
endif

	git clone --single-branch \
	--branch ${GIT_BRANCH} \
	"https://${GIT_USER}:${$@_GIT_TOKEN}@${TARGET_REPO}.git" \
	${TEMP_DIR}

	find ${TEMP_DIR} \( -name "*.go" -or -name "*.mod" -or -name "*.sum" \) -delete;

	$(foreach file,\
	"main.go" \
	,\
	cp -R ${file} ${TEMP_DIR}/${file} ;)

	(cd ${TEMP_DIR} \
	; go mod init ${TARGET_REPO} \
	; go mod tidy)

	(cd ${TEMP_DIR} \
	; git config user.email "${GIT_EMAIL}" \
	; git config user.name "${GIT_USER}" \
	; echo "== git commit ==" \
	; git add . \
	; git commit -m "${GIT_MESSAGE}" \
	; echo "== git remote ==" \
	; git remote -v \
	; echo "== git status ==" \
	; git status \
	; echo '== secrets "${$@_GIT_TOKEN}" ==' \
	; echo "== git push ==" \
	; git config --unset-all http.https://github.com/.extraheader \
	; git push "https://${GIT_USER}:${$@_GIT_TOKEN}@${TARGET_REPO}.git")

ifeq ($(GIT_REF_TYPE),tag)
	(cd ${TEMP_DIR} \
	; echo "== git add tag ==" \
	; git tag -a "${GIT_REF_NAME}" -m "${GIT_MESSAGE}" \
	; echo "== git push tag ==" \
	; git config --unset-all http.https://github.com/.extraheader \
	; git push "https://${GIT_USER}:${$@_GIT_TOKEN}@${TARGET_REPO}.git" --tags)
endif

	rm -rf "${TEMP_DIR}"

.PHONY: lint
lint: install-lint
	${LINTER_BIN} run -v --fix ./...

.PHONY: go-test
go-test:
	go test -count=1 -v ./...

.PHONY: install-lint
install-lint: LINTER_VERSION:=v1.43.0
install-lint:
	$(call fn_install_gotool,github.com/golangci/golangci-lint/cmd/golangci-lint,${LINTER_VERSION},${LINTER_BIN})

# fn_install_gotool installs tool from remote repository
# params:
# 1. remote repository URL
# 2. tag/branch
# 3. path to binary file
# 4. build properties
define fn_install_gotool
	@[ ! -f ${3}@${2} ] \
		|| exit 0 \
		&& echo "Installing ${1} ..." \
		&& tmp=$(shell mktemp -d) \
		&& cd "$$tmp" \
		&& echo "Tool: ${1}" \
		&& echo "Version: ${2}" \
		&& echo "Binary: ${3}" \
		&& echo "Temp: $$tmp" \
		&& go mod init temp && go get -d ${1}@${2} && go build ${4} -o ${3}@${2} ${1} \
		&& ln -sf ${3}@${2} ${3} \
		&& rm -rf "$$tmp" \
		&& echo "success istalled: ${3}" \
		&& echo "********************************************************"
endef

# fn_dowload download tool from remote resource
# params:
# 1. remote repository URL
# 2. tag/branch
# 3. path to binary file
define fn_dowload
	@[ ! -f ${3}@${2} ] \
		|| exit 0 \
		&& echo "Installing ${1} ..." \
		&& wget --no-verbose -O ${3}@${2} ${1} \
		&& ln -sf ${3}@${2} ${3} \
		&& chmod a+x ${3} \
		&& echo "success istalled: ${3}" \
		&& echo "********************************************************"
endef