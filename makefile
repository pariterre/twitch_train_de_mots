
# List of available projects
PROJECTS := client ebs extensions extensions_local

# Folders to keep during web server cleanup
FOLDER_TO_KEEP := .well-known cgi-bin

# Internal variables
BASE_FOLDER := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
WEB_BUILD_FOLDER := build/web

# Make targets
.PHONY: all list $(PROJECTS)

all: list

list:
	@echo "Available projects:"
	@for project in $(PROJECTS); do \
		echo "  - $$project"; \
	done

client:
	@echo "Building CLIENT project..."; \
	PROJECT_FOLDER=$(BASE_FOLDER)/client; \
	cd $${PROJECT_FOLDER}; \
	flutter clean; \
	flutter pub get; \
	flutter build web --release; \
	cd $(BASE_FOLDER); \
	# Make sure the authentication are provided (TRAIN_DE_MOTS_SSH_USER, TRAIN_DE_MOTS_SSH_SERVER, TRAIN_DE_MOTS_SSH_FOLDER_CLIENT) \
	if [ -z "$${TRAIN_DE_MOTS_SSH_USER}" ] || [ -z "$${TRAIN_DE_MOTS_SSH_SERVER}" ] || [ -z "$${TRAIN_DE_MOTS_SSH_FOLDER_CLIENT}" ]; then \
		echo "ERROR -- TRAIN_DE_MOTS_SSH_USER, TRAIN_DE_MOTS_SSH_SERVER, or TRAIN_DE_MOTS_SSH_FOLDER_CLIENT is not set. Please set them before building."; \
		exit 1; \
	fi; \
	ssh $${TRAIN_DE_MOTS_SSH_USER}@$${TRAIN_DE_MOTS_SSH_SERVER} "cd $${TRAIN_DE_MOTS_SSH_FOLDER_CLIENT} && find . $(addprefix ! -name ,$(FOLDER_TO_KEEP)) -delete"; \
	rsync -azvP $${PROJECT_FOLDER}/$(WEB_BUILD_FOLDER)/ $${TRAIN_DE_MOTS_SSH_USER}@$${TRAIN_DE_MOTS_SSH_SERVER}:$${TRAIN_DE_MOTS_SSH_FOLDER_CLIENT}; \
	echo "Project built and sent successfully."

ebs:
	@echo "Building EBS project..."; \
	PROJECT_FOLDER=$(BASE_FOLDER)/ebs; \
	cd $${PROJECT_FOLDER}; \
	dart pub get; \
	dart compile exe bin/train_de_mots_ebs.dart; \
	cd $(BASE_FOLDER); 

extensions:
	@echo "Building EXTENSIONS project..."; \
	CONFIGURATION_FOLDER=$(BASE_FOLDER)/configuration; \
	FRONTEND_FOLDER=$(BASE_FOLDER)/frontend; \
	TARGET_FOLDER=$(BASE_FOLDER)/build; \
	echo "Building extensions..."; \
	cd $${CONFIGURATION_FOLDER} && fvm flutter clean && fvm flutter pub get && fvm flutter build web --no-web-resources-cdn --web-renderer html --release; \
	cd $${FRONTEND_FOLDER}	    && fvm flutter clean && fvm flutter pub get && fvm flutter build web --no-web-resources-cdn --web-renderer html --release; \
	cd $${BASE_FOLDER}; \
	rm -rf $${TARGET_FOLDER}; \
	mkdir $${TARGET_FOLDER}; \
	cp -r $${CONFIGURATION_FOLDER}/$(WEB_BUILD_FOLDER)/ $${TARGET_FOLDER}/configuration/; \
	cp -r $${FRONTEND_FOLDER}/$(WEB_BUILD_FOLDER)/ $${TARGET_FOLDER}/frontend/; \
	cd $${TARGET_FOLDER}; \
	zip -r extensions.zip configuration frontend; \
	cd $(BASE_FOLDER);

extensions_local:
	@echo "Building EXTENSIONS project..."; \
	CONFIGURATION_FOLDER=$(BASE_FOLDER)/configuration; \
	FRONTEND_FOLDER=$(BASE_FOLDER)/frontend; \
	TARGET_FOLDER=$(BASE_FOLDER)/build; \
	echo "Building extensions..."; \
	cd $${CONFIGURATION_FOLDER}  && fvm flutter clean && fvm flutter pub get && fvm flutter build web --no-web-resources-cdn --web-renderer html --profile --dart-define=USE_LOCAL_EBS=true; \
	cd $${FRONTEND_FOLDER}       && fvm flutter clean && fvm flutter pub get && fvm flutter build web --no-web-resources-cdn --web-renderer html --profile --dart-define=USE_LOCAL_EBS=true; \
	cd $${BASE_FOLDER}; \
	rm -rf $${TARGET_FOLDER}; \
	mkdir $${TARGET_FOLDER}; \
	cp -r $${CONFIGURATION_FOLDER}/$(WEB_BUILD_FOLDER)/ $${TARGET_FOLDER}/configuration/; \
	cp -r $${FRONTEND_FOLDER}/$(WEB_BUILD_FOLDER)/ $${TARGET_FOLDER}/frontend/; \
	cd $${TARGET_FOLDER}; \
	zip -r extensions.zip configuration frontend; \
	cd $(BASE_FOLDER);
	
