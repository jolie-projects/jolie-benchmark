include "benchmark/BenchmarkUnit.iol"
include "console.iol"
include "file.iol"
include "runtime.iol"
include "string_utils.iol"
include "time.iol"
include "math.iol"

outputPort BenchmarkUnit {
	Interfaces: BenchmarkUnitInterface
}

constants {
	Rounds = 10,
	Threads = 1,
	Samples = 1,
	TotalSamples = false,
	Increments = 2,
	Exponential = true,
	Name = "JolieBenchmark"
}

define setupOutputFolder {
	testOutputFolder = Name + "-Output";
	isDirectory@File( testOutputFolder )( outputFolderExists );
	if (outputFolderExists == false) {
		mkdir@File( testOutputFolder )( created );
		if (created == false) {
			throw(FolderCouldNotBeCreated, "Unable to create output folder: " + testOutputFolder)
		}
	}
}

define printTableHeader {
	columnWidth = 9;
	columns = 8;
	
	leftPad@StringUtils( "" { .char = "-", .length = columnWidth + 2 } )( columnBorder );		
	rowSeperator = "+";
	for( column = 0, column < columns, column++) {
		rowSeperator += columnBorder + "+"
	};

	leftPad@StringUtils( "Round" { .char = " ", .length = columnWidth } )( roundHeader );
	leftPad@StringUtils( "Threads" { .char = " ", .length = columnWidth } )( threadsHeader );
	leftPad@StringUtils( "Res. Min." { .char = " ", .length = columnWidth } )( minHeader );
	leftPad@StringUtils( "Res. Max." { .char = " ", .length = columnWidth } )( maxHeader );
	leftPad@StringUtils( "Res. Avg." { .char = " ", .length = columnWidth } )( avgHeader );
	leftPad@StringUtils( "Samples/s" { .char = " ", .length = columnWidth } )( throughputHeader );
	leftPad@StringUtils( "Samples" { .char = " ", .length = columnWidth } )( samplesHeader );
	leftPad@StringUtils( "Failed" { .char = " ", .length = columnWidth } )( failedHeader );

	println@Console( rowSeperator )();
	println@Console( "| " + roundHeader + " | " + threadsHeader + " | " + minHeader + " | " + maxHeader + " | " + avgHeader + " | " + throughputHeader + " | " + samplesHeader + " | " + failedHeader + " |")();
	println@Console( rowSeperator )()
}

define printRoundRow {
	samplesCount = 0;
	roundStart = 0;
	roundEnd = 0;
	for( i = 0, i < #results, i++ ) {
		reqs -> results[i].reqs;
		for(r = 0, r < #reqs, r++) {
			request -> reqs[r];
			if (request.success == false) {
				failed++
			};

			if (min == 0 || request.elapsed < min) {
				min = request.elapsed
			};

			if (request.elapsed > max){
				max = request.elapsed
			};

			if (roundStart == 0 || request.start < roundStart) {
				roundStart = request.start
			};

			if (request.end > roundEnd) {
				roundEnd = request.end
			};

			total += request.elapsed;
			count++;
			samplesCount++
		}
	};

	mean = double(total) / ( count - failed );

	roundTime = double(roundEnd - roundStart) / 1000;

	throughput = double(count - failed) / roundTime;

	round@Math( mean { .decimals = 2 } )( mean );
	round@Math( throughput { .decimals = 2 } )( throughput );

	leftPad@StringUtils( string(round) { .char = " ", .length = columnWidth } )( round );
	leftPad@StringUtils( string(threads) { .char = " ", .length = columnWidth } )( threadsPad );
	leftPad@StringUtils( string(mean) { .char = " ", .length = columnWidth } )( mean );
	leftPad@StringUtils( string(min) { .char = " ", .length = columnWidth } )( min );
	leftPad@StringUtils( string(max) { .char = " ", .length = columnWidth } )( max );
	leftPad@StringUtils( string(throughput) { .char = " ", .length = columnWidth } )( throughput );
	leftPad@StringUtils( string(samplesCount) { .char = " ", .length = columnWidth } )( samplesCount );
	leftPad@StringUtils( string(failed) { .char = " ", .length = columnWidth } )( failed );

	println@Console( "| " + round + " | " + threadsPad + " | " + min + " | " + max + " | " + mean + " | " + throughput + " | " + samplesCount + " | " + failed + " |")()
}

define dumpRound {
	filename = testOutputFolder + "/" + threads + "-overall-" + Name + ".csv";
	writeFile@File( { 
	    .content = "timeStamp,elapsed,label,success,fault\n",
	    .append = 0,
	    .filename = filename,
	    .format = "text" } )( );

	for( i = 0, i < #results, i++ ) {
		reqs -> results[i].reqs;
		for(r = 0, r < #reqs, r++) {
			request -> reqs[r];
			writeFile@File( { 
			    .content = request.end + "," + request.elapsed + "," + Name + "," + request.success + "," + request.fault + "\n",
			    .append = 1,
			    .filename = filename,
		    	.format = "text"  } )( )
		}
	}
}

define cleanupEndRound {
	undef( results )
}

define doRound {
	min = 0;
	max = 0;
	mean = 0.0;
	failed = 0;
	count = 0;
	total = 0;
	throughput = 0;
	samplesPerThread = Samples;
	if (TotalSamples) {
		samplesPerThread = 1 + ((double(Samples) - 1) / threads)
	};

	spawn( i over threads ) in results {
		for (req = 0, req < samplesPerThread, req++) {
			doBenchmark@BenchmarkUnit( )( results.reqs[req] )
		}
	};

	if (!warmup) {
		printRoundRow;
		
		dumpRound;

		if (Exponential) {
			threads = threads * Increments
		} else {
			threads += Increments
		}
	}

}

main
{
	if ( is_defined( args[0] ) ) {
		filename = args[0]
	} else {
		helpMsg = "Usage:\n"
			+ "joliebench [options] benchmark_file [arguments]\n\n"
			+ "Options:\n"
			+ "  Regular jolie options. Use constant definitions to alter the behaviour of the benchmark performed. The following constants can be used:\n"
			+ "    Name: The name of the benchmark test. Default is 'JolieBenchmark'.\n"
			+ "    Threads: Number of concurrent threads. Defaults value is 1.\n"
			+ "    Rounds: Number of rounds to execute the benchmark. At each round the number of threads is incremented by 'Increments'. Defaults value is 1.\n"
			+ "    Increments: How many threads to add to the number of thread at the end of each round. Defaults value is 2.\n"
			+ "    Exponential: If true the value of 'Increment' is multiplied to the number of threads, otherwise it is simply added. Defaults value is 'true'.\n"
			+ "    Samples: number of times each thread executes the test. Defaults value is 1.\n"
			+ "    TotalSamples: If true the value of 'Samples' is interpreted as a total number of samples across all threads, hence the value of 'Samples' is divided by the number of threads. The resulting number of samples each threads makes is rounded up, effectivly making 'Samples' a lowerbound of the total number of reuqests. If the value is 'false' each thread executes the benchmark test exactly 'Samples' times. Defaults value is 'false'.\n"
			+ "    Threads: used to define the number of concurrent threads. Defaults value is 1.\n";
		println@Console( helpMsg )();
		throw( MissingArgument, "A test file must be specified" )
	};

	getCurrentTimeMillis@Time( )( testStart );

	setupOutputFolder;

	loadRequest.type = "Jolie";
	loadRequest.filepath = filename;
	scope( s ) {
		install( RuntimeException => println@Console( s.RuntimeException.stackTrace )() );
		
		loadEmbeddedService@Runtime( loadRequest )( BenchmarkUnit.location );

		println@Console( "Starting test with: " + Threads + " concurrent threads performing the benchmark definition " + Samples + " times each. Test is executed over " + Rounds + " rounds.")();

		printTableHeader;		

		threads = Threads;

		warmup = true;
		doRound;
		warmup = false;

		for( round = 1, round <= Rounds, round++) {
			doRound
		};

		println@Console( rowSeperator )();

		callExit@Runtime( BenchmarkUnit.location )()
	}
}
