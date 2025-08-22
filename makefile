
# List of available projects
PROJECTS := client extensions

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
	# Make sure the authentication are provided (SSH_USER, SSH_SERVER, SSH_FOLDER_CLIENT) \
	if [ -z "$${SSH_USER}" ] || [ -z "$${SSH_SERVER}" ] || [ -z "$${SSH_FOLDER_CLIENT}" ]; then \
		echo "ERROR -- SSH_USER, SSH_SERVER, or SSH_FOLDER_CLIENT is not set. Please set them before building."; \
		exit 1; \
	fi; \
	cd $${PROJECT_FOLDER}; \
	flutter clean; \
	flutter pub get; \
	flutter build web --release; \
	cd $(BASE_FOLDER); \
	ssh $${SSH_USER}@$${SSH_SERVER} "cd $${SSH_FOLDER_CLIENT} && find . $(addprefix ! -name ,$(FOLDER_TO_KEEP)) -delete"; \
	rsync -azvP $${PROJECT_FOLDER}/$(WEB_BUILD_FOLDER)/ $${SSH_USER}@$${SSH_SERVER}:$${SSH_FOLDER_CLIENT}; \
	echo "Project built and sent successfully."

extensions:
	@echo "Building EXTENSIONS project..."; \
	CONFIGURATION_FOLDER=$(BASE_FOLDER)/configuration; \
	FRONTENDS_FOLDER=$(BASE_FOLDER)/frontends; \
	TARGET_FOLDER=$(BASE_FOLDER)/build; \
	echo "Building extensions..."; \
	cd $${CONFIGURATION_FOLDER}             && flutter clean && fvm flutter pub get && fvm flutter build web --no-web-resources-cdn --web-renderer html --release; \
	cd $${FRONTENDS_FOLDER}/video_component && flutter clean && fvm flutter pub get && fvm flutter build web --no-web-resources-cdn --web-renderer html --release; \
	cd $${FRONTENDS_FOLDER}/video_overlay 	&& flutter clean && fvm flutter pub get && fvm flutter build web --no-web-resources-cdn --web-renderer html --release; \
	cd $${BASE_FOLDER}; \
	rm -rf $${TARGET_FOLDER}; \
	mkdir $${TARGET_FOLDER}; \
	cp -r $${CONFIGURATION_FOLDER}/$(WEB_BUILD_FOLDER)/ $${TARGET_FOLDER}/configuration/; \
	cp -r $${FRONTENDS_FOLDER}/video_component/$(WEB_BUILD_FOLDER)/ $${TARGET_FOLDER}/video_component/; \
	cp -r $${FRONTENDS_FOLDER}/video_overlay/$(WEB_BUILD_FOLDER)/ $${TARGET_FOLDER}/video_overlay/; \
	cd $${TARGET_FOLDER}; \
	zip -r extensions.zip configuration video_component video_overlay; \
	cd $(BASE_FOLDER); \
	
