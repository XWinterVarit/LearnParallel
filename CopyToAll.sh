#!/usr/bin/env bash
#docker cp dockeropenmpi_mpi_head_1:/home/mpirun/hello hello
#docker cp hf dockeropenmpi_mpi_head_1:/home/mpirun/hf
#docker cp hello dockeropenmpi_mpi_head_1:/home/mpirun/hello
#docker cp hello dockeropenmpi_mpi_node_1:/home/mpirun/hello
#docker cp hello dockeropenmpi_mpi_node_2:/home/mpirun/hello
#docker cp hello dockeropenmpi_mpi_node_3:/home/mpirun/hello



#docker cp MultiplicationOpenMp.c dockeropenmpi_mpi_head_1:/home/mpirun/MultiplicationOpenMp.c
#docker cp MultiplicationSeq.c dockeropenmpi_mpi_head_1:/home/mpirun/MultiplicationSeq.c


scp -r ./Countword/ cheevarit@158.108.38.91:~/ -P 55555