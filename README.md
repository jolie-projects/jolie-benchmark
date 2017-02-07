# JolieBenchmark
*JolieBenchmark* is a benchmarking framework written in *Jolie*. The framework allows for rapid development of benchmarks, that tests throughput and response time of distributed services. This gives Jolie developers a native tool, to implement performance tests for Jolie services.

As Jolie supports several protocols and networking mediums, benchmarks written for *JolieBenchmark* are not restricted to services implemented in Jolie.

**Remark:** The *JolieBenchmark* tool was developed alongside my master's thesis on implementing an event-driven version of the *Jolie* interpreter. 
In the thesis, an earlier version of the tool is presented. Since the thesis, additional work has been put into streamlining the development 
of benchmarks, better configuration options and updated the graphing tool to produce easier-to-read graphs.

In this repository, you are able to find the most current version of *JolieBenchmark* along with a comprehensive user's guide, complete with examples 
and configuration options.

## System requirements
The following libraries are required:
* [Jolie](https://github.com/jolie/jolie)

Further information on installing Jolie, can be found on the official [website](http://jolie-lang.org/downloads.html).

## Getting Started
To get started you can clone this repository, or copy the files in the `src/` folder to your working directory. When implementing benchmarks both the *JolieBenchmark* tool `benchmark.ol` and your benchmark implementations must be able to include the `.iol` files provided in this repository.

Another possibility is to add the files to your Jolie path, so they can be globally referenced by your Jolie code. To do so copy the files into `$JOLIE_HOME/include` while preserving the folder structure. The files should then be locatable at:
```
$JOLIE_HOME/include/benchmark.ol
$JOLIE_HOME/include/benchmark/AbstractBenchmarkUnit.iol
$JOLIE_HOME/include/benchmark/BenchmarkUnit.iol
```
**Note:** to avoid copying files upon updates, you could use symbolic links to link the files directly from the cloned repository into your Jolie path.

### Hello World

To implement a benchmark for *JolieBenchmark*, you need to include the `AbstractBenchmarkUnit.iol` and define a procedure called `benchmark`. Thus the minimum required implementation is:
```
include "benchmark/AbstractBenchmarkUnit.iol"

define benchmark
{
	// Place the operation calls you wish to benchmark here
	nullProcess
}
```
This example simply tests the performance of executing procedures in the Jolie interpreter itself. However it should be clear that by replacing the `nullProcess` with calls to an external service, an external service is just as easily benchmarked. See the example below.


### Running

To run a benchmark you must execute *JolieBenchmark* and pass your benchmark as a command line argument. To execute the Hello World example above, you can save the code in a file called `helloworld.ol` and then the benchmark by executing:

```
jolie $JOLIE_HOME/include/benchmark.ol /path/to/helloworld.ol
```
**Note:** This expects *JolieBenchmark* to be installed in your `$JOLIE_HOME` path, as described in *Getting Started*.

## Configuration

*JolieBenchmark* has several configuration options that can be used to alter the behaviour of the benchmark. The options can set by defining Jolie constants from the command line. For example
```
jolie -C "Threads=100" -C "Increments=100" -C "Exponential=false" $JOLIE_HOME/include/benchmark.ol /path/to/helloworld.ol
```
The following tables describes the supported configuration options:

| Constant name            | Default value              | Description                 |
| :--------------- | :------------------- | :---------------------------|
| `Name`       | `JolieBenchmark` | The name of the benchmark. The name is used to specify which folder the benchmark results are dumped to, and is shown in the produced graphs. |
| `Rounds`   		| `10` 		| Specifies the number of rounds to execute the benchmark. At each round the number of threads is incremented by `Increments`. |
| `Threads`     	| `1`   	| Specifies the number of concurrent threads used in the first round. |
| `Increments`      | `2`		| How much the number of threads is incremented after each round. If `Exponential` is set to `true` the value of `Increments` is multiplied to the the number of threads, otherwise it is added. |
| `Exponential`		| `true`	| If `true` the value of `Increments` is multiplied to the number of threads, otherwise it is simply added. |
| `Samples`     	| `1` 		| The number of times each thread executes the benchmark definition before exiting. By increasing `Samples` it is possible to minimize the overhead of spawning threads compared to the the cost of performing individual samples. |
| `TotalSamples` 	| `false`	| If `true` the value of `Samples` is interpreted as a total number of requests across all threads, hence the value of `Samples` is divided by the number of threads. The number of samples each thread makes, at any given round, is given by `ceil( Samples / #threads )` where `#threads` is the current number of threads. If the value is `false` each thread executes the benchmark definition `Samples` times. |

## Output
When performing a benchmark, *JolieBenchmark* will for each round print the results to the console. For each round the following information is printed:

| Column            | Description              |
| :--------------- | :------------------- |
| Round 		| Indicates the current round. |
| Threads 		| The number of threads used in the current round. |
| Res. Min. 	| The minimum response time of all samples in the current round, from the point of view of *JolieBenchmark*. This is equivalent to the minimum number of milliseconds a `benchmark` procedure was executing. |
| Res. Max. 	| The maximum response time of all samples in the current round, from the point of view of *JolieBenchmark*. This is equivalent to the maximum number of milliseconds a `benchmark` procedure was executing. |
| Res. Avg. 	| The average response time of all samples in the current round, from the point of view of *JolieBenchmark*. This is equivalent to the average number of milliseconds a `benchmark` procedure was executing. |
| Throughput 	| The calculated throughput given by the number of successful samples per second. |
| Samples 		| The total number of samples executed in this round. This equals the number of threads times the number of samples per thread. |
| Failed 		| The number of failed samples. A sample is considered failed, if an uncaught fault is thrown in the `benchmark` procedure. |

Similarly for each round a `.csv` file is dumped into a folder called `TESTNAME-Output/`, where `TESTNAME` is the name defined for the current test. The `.csv` files are named according to `XX-overall-TESTNAME.csv`, where `xx` is the number of threads used.

The `.csv` files contains a row for each sample, so that the result of individual samples can be inspected, and contains the following 5 columns:

| Column            | Description              |
| :--------------- | :------------------- |
| timestamp | The UNIX timestamp of when the sample finished executing. |
| elapsed 	| The number of milliseconds the sample was executing. |
| label 	| The name of the benchmark. |
| success 	| A boolean indication whether the sample executed successfully. |
| fault 	| If the sample failed, this columns contains the name of the fault thrown. |


### Generating graphs

The generated `.csv` files can be used to produce a graph of the benchmark results. The graph produced plots throughput and response time for each round. To produce graphs, a small Python script `graph.py` is included in the repository.

The graph script has the following requirements:

* Python
* MatPlotLib - 2.0 + (For producing graphs)

To generate a graph of the dumped benchmark results, you run the following command inside the output folder:
```
python /path/to/graph.py *.csv
```
A graph generated by this script will contain the following:

 - Throughput plotted as a line
 - Response times plotted as box plots, to visualize how response times are distributed. The boxplots include a triangle indicating the average response time.

An example graph can be seen below:

![img](http://i68.tinypic.com/f1kqvb.png)

## Example - Benchmarking a Jolie service
As an example let us consider the task of benchmarking a simple Jolie service that sums numbers. The service is seen below and consists of a single operation that sums two numbers and send the result back as response.
```
include "suminterface.iol"

inputPort SodepInput {
	Location: "socket://localhost:8002/"
	Protocol: sodep
	Interfaces: SumInterface
}

execution { concurrent }

main
{
	sum( request )( response ) {
		response = request.x + request.y
	}
}
```
By saving the code above in a file called `sumserver.ol`, we are able to run the server by:
```
jolie /path/to/sumserver.ol
```

### Benchmark
To implement the benchmark we include `AbstractBenchmarkUnit.iol` and define the `benchmark` procedure as follows.
`sumbenchmark.ol`:
```
include "benchmark/AbstractBenchmarkUnit.iol"

include "suminterface.iol"

outputPort Server {
	Location: "socket://localhost:8002/"
	Protocol: sodep {
		.keepAlive = true
	}
	Interfaces: SumInterface
}

define benchmark
{
	sum@Server( { .x = 6, .y = 4} )( res )
}
```

### Running
For the sake of the example we set the starting number of threads to 10 when executing the benchmark. We also increase the number of rounds to 14, to test our server under even more concurrent threads.
```
jolie -C "Samples=10" -C "Rounds=14" $JOLIE_HOME/include/benchmark.ol sumbenchmark.ol
```

### Output:
In the command line the following results are produced:
```
+------------+------------+------------+------------+------------+------------+------------+------------+
|      Round |    Threads |  Res. Min. |  Res. Max. |  Res. Avg. | Throughput |    Samples |     Failed |
+------------+------------+------------+------------+------------+------------+------------+------------+
|          1 |          1 |          0 |          2 |        1.0 |      666.7 |         10 |          0 |
|          2 |          2 |          0 |          2 |        0.9 |     1538.5 |         20 |          0 |
|          3 |          4 |          0 |          7 |        1.4 |     1818.2 |         40 |          0 |
|          4 |          8 |          1 |          6 |        1.5 |     3200.0 |         80 |          0 |
|          5 |         16 |          1 |          9 |        2.4 |     4210.5 |        160 |          0 |
|          6 |         32 |          1 |         17 |        4.4 |     4637.7 |        320 |          0 |
|          7 |         64 |          2 |         24 |        5.5 |     6274.5 |        640 |          0 |
|          8 |        128 |          1 |         23 |        7.0 |     8827.6 |       1280 |          0 |
|          9 |        256 |          1 |         24 |       11.2 |    11377.8 |       2560 |          0 |
|         10 |        512 |          1 |         95 |       29.0 |     7840.7 |       5120 |          0 |
|         11 |       1024 |          7 |        128 |       40.9 |    10189.1 |      10240 |          0 |
|         12 |       2048 |          1 |        145 |       60.8 |    14514.5 |      20480 |          0 |
|         13 |       4096 |          1 |       2332 |      248.9 |     8497.9 |      40960 |          0 |
|         14 |       8192 |          1 |       1644 |      299.2 |    11831.3 |      81920 |          0 |
+------------+------------+------------+------------+------------+------------+------------+------------+
```

Using the graph script `graph.py`, a graph like the following can be produced:

![img](http://i68.tinypic.com/n1s5ds.png)
