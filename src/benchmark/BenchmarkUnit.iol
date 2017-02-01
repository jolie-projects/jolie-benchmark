type BenchmarkResult:void {
	.start:long
	.end:long
	.elapsed:long
	.success:bool
	.fault?:string
}

interface BenchmarkUnitInterface {
RequestResponse:
	doBenchmark( void )( BenchmarkResult )
}
