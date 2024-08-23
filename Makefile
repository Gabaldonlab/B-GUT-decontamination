docker-image:
	@docker image rm -f olfat-debug:latest
	@docker image build -t olfat-debug:latest .

docker-container:
	@docker container rm -f olfat-debug
	@docker container run -dit --name olfat-debug olfat-debug:latest
	@docker exec -it olfat-debug bash

singularity-image:
	./scripts/get_singularity_def_file_from_dockerfile.sh
	sudo singularity build my_singularity.sif my_singularity.def