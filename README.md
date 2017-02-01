# JolieBenchmark
*JolieBenchmark* is a benchmarking framework written in *Jolie*. The framework allows for rapid development of bechmarks, that tests througput and responsetime of distributed services. This give *Jolie* developers a native tool, to implement performance tests for Jolie services.

As Jolie supports several protocols and networking mediums, benchmarks are not restricticted to Jolie services, and can be used to benchmark any service running protocols supported by Jolie.

## System requirements
The following libraries are required:
* [Jolie](https://github.com/jolie/jolie) 
* MatPlotLib - 2.0 + (For producing graphs)

Further information on installing Jolie, can be found on the offical [website](http://jolie-lang.org/downloads.html).

## Getting Started
To get started you can clone this repository, or copy the files in the `src/` folder. When implementing benchmarks both the `benchmark.ol` and your benchmark implemention must be able to include the `iol` files provided in this repository.

Another posibility is to add the files to your Jolie path, so they can be globally referenced. To do so copy the files into `$JOLIE_HOME/include` while preserving the structure. Thus you should achieve the following structure:
```
$JOLIE_HOME/include/benchmark.ol
$JOLIE_HOME/include/benchmark/AbstractBenchmarkUnit.iol
$JOLIE_HOME/include/benchmark/BenchmarkUnit.iol
```
**Note:** to avoid copying files upon updates, you could use symbolic links to link the files directly from a cloned repository. 

### Running

If *JolieBenchmark* is installed in your `$JOLIE_HOME` path, you can run your benchmark by executing:

```
$jolie $JOLIE_HOME/include/benchmark.ol sample.ol 
```

### Hello World

To implement a benchmark in *JolieBenchmark*, you need to include the `AbstractBenchmarkUnit.iol` and define a procedure called `Benchmark`. Thus the minimum required implementation is:
```
include "benchmark/AbstractBenchmarkUnit.iol"

define benchmark
{
	// Place the operation calls you wish to benchmark here
	nullProcess
}

```
This example will simply test the performance of the Jolie interpreter itself. It should however be clear that by simply defining an output port to an external service and placing calls to the service in the `Benchmark` procedure, an external service is as easily benchmarked. See the example below.

## Configuration

*JolieBenchmark* has several configuration constants that makes it possible to alter the behaviour benchmark. Configurations options can set by defining Jolie constants from the command line.  
```
$jolie -C "Threads=100" -C "Increments=100" -C "Exponential=false" ../benchmark.ol sumbenchmark.ol 
```
Below is a table describing all the supported configuration constants:

| Constant            | Default              | Description                 |
| :--------------- | :------------------- | :---------------------------|
| `Name`       | `JolieBenchmark` | The name of the benchmark test. The name is used to specify which folder the benchmark results are dumped to, and is shown in the produced graphs. |
| `Rounds`   		| `10` 		| Specifies the number of rounds to execute the benchmark. At each round the number of threads is incremented by `Increments`. |
| `Threads`     	| `1`   	| Specifies the number of concurrent threads  |
| `Samples`     	| `1` 		| Specifies the number of times each thread executes the benchmark definition. |
| `Increments`      | `2`		| How much the number of threads is incremented each round. If `Exponential` is set to `true` the value of `Increments` is multiplied to the the number of threads. |
| `Exponential`		| `true`	| If true the value of `Increment` is multiplied to the number of threads, otherwise it is simply added. |
| `TotalSamples` 	| `false`	| If true the value of `Samples` is interpreted as a total number of requests across all threads, hence the value of `Samples` is divided by the number of threads. The number of samples each thread makes, at any given roung, is given by `ceil( Samples / #threads )` where `#threads` is the current number of threads. If the value is `false` each thread executes the benchmark definition `Samples` times |

## Output
When performing a benchmark, *JolieBenchmark* will for each round print the results to the console. For each round the following information is printed:

| Column            | Description              |
| :--------------- | :------------------- |
| Round 	| The current round number. |
| Threads 	| The number of threads used in this round. |
| Res. Min. | The minimum response time of any definition execution. |
| Res. Max. | The maximum response time. |
| Res. Avg. | The avarage response time. |
| Samples/s | The calculated throughput given by the number of successfull samples per sencond. |
| Samples 	| The total number of samples executed in this round. |
| Failed 	| The number of failed samples. A sample is considered failed, if an uncaught fault is thrown in the `Benchmark` procedure. |

Similarly for each round a `.csv` file is dumped into a folder called `TESTNAME-Output/`, where `TESTNAME` is the name defined for the current test. The `.csv` files are named according to `XX-overall-TESTNAME.csv`, where `xx` is the number of threads used.

The `.csv` files contains a row for each sample, so that the result of individual samples can be inspected, and contains the following 5 columns:

| Column            | Description              |
| :--------------- | :------------------- |
| timestamp | The UNIX timestamp of when the sample finished. |
| elapsed 	| The number of milliseconds the sample took to finish. |
| label 	| The name of the benchmark. |
| success 	| A boolean field indication wheter the sample succeeded. |
| fault 	| If the sample failed, this columns contains the name of the fault thrown. |

These files can be used to generate graph of the results, displaying througput and response time for each round. A graph is generated by executing the follwing command inside the output folder:
```
python graph.py *.csv
```
A graph generated by this scipt is seen in the example below.

## Example
As an example lets consider the task of benchmarking a simple Jolie service that sums numbers. The service is seen below and consits of a single operation that sums two numbers and send the result back as response.
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

### Benchmark
To implement the becnhmark we include `AbstractBenchmarkUnit.iol` and defines the `Benchmark` procedure as follows:
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
For the sake of the example we set the starting number of threads to 10 when executing the benchmark.
```
jolie -C "Threads=10" -C "Samples=2" $JOLIE_HOME/include/benchmark.ol sumbenchmark.ol
```

### Output:
In the command line the following results are produced:
```
+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
|     Round |   Threads | Res. Min. | Res. Max. | Res. Avg. | Samples/s |   Samples |    Failed |
+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
|         1 |        10 |         1 |         4 |       2.5 |    2000.0 |        10 |         0 |
|         2 |        20 |         3 |         7 |       4.5 |   2222.22 |        20 |         0 |
|         3 |        40 |         3 |        12 |       8.6 |   2352.94 |        40 |         0 |
|         4 |        80 |         3 |        25 |     12.44 |   2857.14 |        80 |         0 |
|         5 |       160 |         7 |        43 |      24.3 |   3018.87 |       160 |         0 |
|         6 |       320 |         6 |        75 |      38.1 |   3855.42 |       320 |         0 |
|         7 |       640 |         9 |       111 |     52.34 |    5245.9 |       640 |         0 |
|         8 |      1280 |        15 |       159 |     73.03 |   7111.11 |      1280 |         0 |
|         9 |      2560 |        15 |       169 |     92.54 |   8677.97 |      2560 |         0 |
|        10 |      5120 |        57 |       492 |    209.17 |   8998.24 |      5120 |         0 |
+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
```
**Note:** results may vary.

Using the graph script, a graph like the following can be generated:
![img](http://i65.tinypic.com/fc0bhf.png)
