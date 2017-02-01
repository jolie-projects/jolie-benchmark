include "BenchmarkUnit.iol"
include "time.iol"

inputPort BenchmarkUnitInput {
Location: "local"
Interfaces: BenchmarkUnitInterface
}

define handleFault {
	result.success = false;
	getCurrentTimeMillis@Time( )( result.end );
	result.elapsed = result.end - result.start;
	result.fault = string(s.default)
}

execution { concurrent }

main
{
	doBenchmark( )( result ) {
		scope( s ) {
			install( default => handleFault );
			getCurrentTimeMillis@Time( )( result.start );
			benchmark;
			getCurrentTimeMillis@Time( )( result.end );
			result.elapsed = result.end - result.start;
			result.success = true
		}
	}
	
}
