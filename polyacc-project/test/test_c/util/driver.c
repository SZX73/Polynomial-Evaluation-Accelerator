/*
* This is the main executable for testing the LIDE-C PEA actor.
*
* It follows the pattern from 'hist_actor_project/test/util/hist_actor_driver.c'.
*
* It is responsible for:
* 1. Reading file names from command line arguments.
* 2. Creating all FIFOs.
* 3. Instantiating all actors (file sources, file sinks, and the PEA).
* 4. Connecting actors to the FIFOs.
* 5. Running the simple scheduler.
* 6. Terminating actors and freeing FIFOs.
*
* USAGE:
* driver.exe control_in.txt data_in.txt result_out.txt status_out.txt
*/


#include <stdio.h>
#include <stdlib.h>
#include "lide_c_actor.h"
#include "lide_c_fifo.h"
#include "lide_c_util.h" /* This is needed for the simple scheduler */
#include "lide_c_file_source.h"
#include "lide_c_file_sink.h"
#include "pea_c_actor.h" /* Your actor */


/* Actor and FIFO definitions for the test graph */
#define ACTOR_COUNT 5
#define ACTOR_CONTROL_SOURCE 0
#define ACTOR_DATA_SOURCE 1
#define ACTOR_PEA 2
#define ACTOR_RESULT_SINK 3
#define ACTOR_STATUS_SINK 4


#define FIFO_COUNT 4
#define FIFO_CONTROL 0
#define FIFO_DATA 1
#define FIFO_RESULT 2
#define FIFO_STATUS 3


#define BUFFER_CAPACITY 1024


int main(int argc, char **argv) {
   lide_c_actor_context_type *actors[ACTOR_COUNT];
   lide_c_fifo_pointer fifos[FIFO_COUNT];
   int token_size = sizeof(int);
   int i = 0;


   /* * Actor names for diagnostic output
    * THIS IS THE FIX for 'LIDE_C_DESCRIPTOR_NAME_MAX_SIZE'
    * We just define a static array of strings, like in Lab 6.
    */
   char *descriptors[ACTOR_COUNT] = {
       "ControlSource",
       "DataSource",
       "PEA_Actor",
       "ResultSink",
       "StatusSink"
   };


   /* Check program usage */
   if (argc != 5) {
       fprintf(stderr, "polyacc driver.exe error: incorrect arg count.\n");
       fprintf(stderr,
               "Usage: %s <control_in> <data_in> <result_out> <status_out>\n",
               argv[0]);
       exit(1);
   }


   /* Instantiate FIFOs */
   for (i = 0; i < FIFO_COUNT; i++) {
       fifos[i] = lide_c_fifo_new(BUFFER_CAPACITY, token_size);
       if (fifos[i] == NULL) {
            fprintf(stderr, "Error: Failed to allocate FIFO %d\n", i);
            exit(1);
       }
   }


   /* Instantiate and connect actors */


   /* 1. Control File Source -> FIFO_CONTROL */
   actors[ACTOR_CONTROL_SOURCE] = (lide_c_actor_context_type *)
       lide_c_file_source_new(argv[1], fifos[FIFO_CONTROL]);


   /* 2. Data File Source -> FIFO_DATA */
   actors[ACTOR_DATA_SOURCE] = (lide_c_actor_context_type *)
       lide_c_file_source_new(argv[2], fifos[FIFO_DATA]);


   /* 3. PEA Actor */
   actors[ACTOR_PEA] = (lide_c_actor_context_type *)
       lide_c_pea_actor_new(fifos[FIFO_CONTROL],
                              fifos[FIFO_DATA],
                              fifos[FIFO_RESULT],
                              fifos[FIFO_STATUS]);


   /* 4. FIFO_RESULT -> Result File Sink */
   actors[ACTOR_RESULT_SINK] = (lide_c_actor_context_type *)
       lide_c_file_sink_new(argv[3], fifos[FIFO_RESULT]);


   /* 5. FIFO_STATUS -> Status File Sink */
   actors[ACTOR_STATUS_SINK] = (lide_c_actor_context_type *)
       lide_c_file_sink_new(argv[4], fifos[FIFO_STATUS]);


   /* Execute the graph */
   lide_c_util_simple_scheduler(actors, ACTOR_COUNT, descriptors);


   /* Terminate and free memory */
   lide_c_file_source_terminate((lide_c_file_source_context_type *)
                                    actors[ACTOR_CONTROL_SOURCE]);
   lide_c_file_source_terminate((lide_c_file_source_context_type *)
                                    actors[ACTOR_DATA_SOURCE]);
   lide_c_pea_actor_terminate((lide_c_pea_actor_context_type *)
                                    actors[ACTOR_PEA]);
   lide_c_file_sink_terminate((lide_c_file_sink_context_type *)
                                  actors[ACTOR_RESULT_SINK]);
   lide_c_file_sink_terminate((lide_c_file_sink_context_type *)
                                  actors[ACTOR_STATUS_SINK]);


   for (i = 0; i < FIFO_COUNT; i++) {
       lide_c_fifo_free(fifos[i]);
   }


   return 0;
}

