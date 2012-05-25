all:	test

test:	test_rack_stack test_rack_builder_compatibility test_sample_use_cases

test_rack_stack:
	./run-tests

test_rack_builder_compatibility:
	cd spec/rack-builder-compatibility && ./run-tests

test_sample_use_cases: test_sample_use_case_artifice

test_sample_use_case_artifice:
	cd spec/sample-use-cases/artifice/ && ./run-tests
