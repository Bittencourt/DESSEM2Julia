# Error Handling Tests - Phase 1 (DEBT-08)
#
# This test file verifies that all parsers throw ParserError with proper context
# instead of generic MethodError/ErrorException. It covers:
# - ERR-01: All parsers use ParserError (contract verification)
# - ERR-02: Capacity validation error path
# - ERR-03: Heat rate validation error path
# - ERR-04: Silent failure elimination in operuh.jl
# - ParserError structure and context verification
#
# These tests ensure that error handling improvements from Plans 01-01 through 01-03
# are maintained and catch future regressions.

using Test
using DESSEM2Julia
using DESSEM2Julia.ParserCommon
using DESSEM2Julia.TermdatParser: parse_cadunidt, parse_curvacomb
using DESSEM2Julia.OperuhParser: parse_rest_record, parse_elem_record, parse_lim_record, parse_var_record
using DESSEM2Julia.SimulParser: parse_simul_header, parse_disc_record, parse_voli_record, parse_oper_record
using DESSEM2Julia.RenovaveisParser: parse_renovaveis_record

@testset "Error Handling - Phase 1" begin
    
    @testset "ParserError Structure" begin
        @testset "Contains required fields" begin
            err = ParserError("Test message", "test.dat", 42, "test line content")
            @test err.msg == "Test message"
            @test err.file == "test.dat"
            @test err.line == 42
            @test err.content == "test line content"
        end
        
        @testset "Formatted output includes context" begin
            err = ParserError("Test error", "test.dat", 42, "problematic line")
            io = IOBuffer()
            showerror(io, err)
            msg = String(take!(io))
            @test occursin("test.dat:42", msg)
            @test occursin("Test error", msg)
            @test occursin("problematic line", msg)
        end

        @testset "Error message is descriptive" begin
            err = ParserError("Field 'capacity' must be positive, got -5", "TERM.DAT", 10, "CADUNIDT   1  1 2025 01 01 00 0      -5.000     10.000     0     0")
            io = IOBuffer()
            showerror(io, err)
            msg = String(take!(io))
            @test occursin("Field 'capacity' must be positive", msg)
            @test occursin("TERM.DAT", msg)
        end
    end
    
    @testset "ERR-01: All parsers use ParserError" begin
        @testset "No generic ArgumentError for invalid format" begin
            # Missing required field should throw ParserError, not ArgumentError
            line_missing_required = "CADUSIT"  # Too short - missing required fields
            
            @test_throws ParserError extract_fields(
                line_missing_required,
                [FieldSpec(:plant_num, 9, 11, Int; required=true)],
                file="test.dat",
                line_num=1
            )
        end

        @testset "Type conversion failures throw ParserError" begin
            # Invalid integer should be wrapped in ParserError
            line = "CADUNIDT ABC 0012024 01 01 00 0       100.0      200.0"
            
            try
                parse_cadunidt(line, "test.dat", 1)
                @test false  # Should not reach here
            catch e
                @test isa(e, ParserError)
                @test !isa(e, MethodError)
                @test !isa(e, ArgumentError)
            end
        end
    end
    
    @testset "ERR-02: Capacity Validation" begin
        @testset "min_generation > capacity throws ParserError" begin
            # Create test data where min (200.0) > capacity (100.0)
            invalid_line = "CADUNIDT 001 0012024 01 01 00 0       100.0      200.0"
            
            @test_throws ParserError parse_cadunidt(invalid_line, "test.dat", 1)
        end

        @testset "Capacity validation error includes file and line" begin
            invalid_line = "CADUNIDT 001 0012024 01 01 00 0       100.0      200.0"
            
            try
                parse_cadunidt(invalid_line, "custom.dat", 42)
            catch e
                @test isa(e, ParserError)
                @test occursin("Minimum generation", e.msg)
                @test occursin("exceeds", lowercase(e.msg))
                @test e.file == "custom.dat"
                @test e.line == 42
                @test e.content == invalid_line
            end
        end

        @testset "Does NOT throw MethodError for capacity validation" begin
            invalid_line = "CADUNIDT 001 0012024 01 01 00 0       100.0      200.0"
            
            try
                parse_cadunidt(invalid_line, "test.dat", 1)
                @test false  # Should not reach here
            catch e
                @test !isa(e, MethodError)
                @test isa(e, ParserError)
            end
        end

        @testset "Valid data passes capacity check" begin
            valid_line = "CADUNIDT 001 0012024 01 01 00 0       200.0      100.0"
            result = parse_cadunidt(valid_line, "test.dat", 1)
            @test result.unit_capacity == 200.0
            @test result.min_generation == 100.0
        end

        @testset "Equal min and capacity is valid" begin
            equal_line = "CADUNIDT 001 0012024 01 01 00 0       100.0      100.0"
            result = parse_cadunidt(equal_line, "test.dat", 1)
            @test result.unit_capacity == 100.0
            @test result.min_generation == 100.0
        end
    end
    
    @testset "ERR-03: Heat Rate Validation" begin
        @testset "Zero heat_rate throws ParserError" begin
            zero_heat_line = "CURVACOMB 001 001    0      100.0"
            @test_throws ParserError parse_curvacomb(zero_heat_line, "test.dat", 1)
        end

        @testset "Negative heat_rate throws ParserError" begin
            negative_heat_line = "CURVACOMB 001 001   -5      100.0"
            @test_throws ParserError parse_curvacomb(negative_heat_line, "test.dat", 1)
        end

        @testset "Heat rate validation error includes context" begin
            zero_heat_line = "CURVACOMB 001 001    0      100.0"
            
            try
                parse_curvacomb(zero_heat_line, "heat.dat", 42)
            catch e
                @test isa(e, ParserError)
                @test e.file == "heat.dat"
                @test e.line == 42
                @test occursin("heat_rate", lowercase(e.msg))
            end
        end

        @testset "Valid heat rate passes validation" begin
            valid_line = "CURVACOMB 001 001 9000      100.0"
            result = parse_curvacomb(valid_line, "test.dat", 1)
            @test result.heat_rate == 9000
            @test result.generation == 100.0
        end
    end
    
    @testset "ERR-04: Silent Failures Eliminated (operuh.jl)" begin
        @testset "Invalid REST record throws ParserError not silently returns nothing" begin
            # Malformed REST record - should throw ParserError
            invalid_rest = "OPERUH REST   XXXXX  L     RHQ"
            
            try
                parse_rest_record(invalid_rest, "test.dat", 1)
                @test false  # Should not reach here
            catch e
                @test isa(e, ParserError)
                @test !isa(e, MethodError)
                @test e.file == "test.dat"
                @test e.line == 1
            end
        end

        @testset "Invalid ELEM record throws ParserError" begin
            invalid_elem = "OPERUH ELEM   00066  XX  INVALID        ABC"
            
            try
                parse_elem_record(invalid_elem, "test.dat", 5)
                @test false  # Should not reach here
            catch e
                @test isa(e, ParserError)
                @test e.file == "test.dat"
                @test e.line == 5
            end
        end

        @testset "Invalid LIM record throws ParserError" begin
            # Invalid constraint_id (non-numeric)
            invalid_lim = "OPERUH LIM    XXXXX  I       F                         600.00"
            
            try
                parse_lim_record(invalid_lim, "test.dat", 10)
                @test false  # Should not reach here
            catch e
                @test isa(e, ParserError)
                @test e.file == "test.dat"
                @test e.line == 10
            end
        end

        @testset "Invalid VAR record throws ParserError" begin
            invalid_var = "OPERUH VAR    XXXXX I       F                                          600.00"
            
            try
                parse_var_record(invalid_var, "test.dat", 15)
                @test false  # Should not reach here
            catch e
                @test isa(e, ParserError)
                @test e.file == "test.dat"
                @test e.line == 15
            end
        end

        @testset "Valid records parse successfully" begin
            valid_rest = "OPERUH REST   00066  L     RHQ               489.00      15.00"
            result = parse_rest_record(valid_rest, "test.dat", 1)
            @test result.constraint_id == 66

            valid_elem = "OPERUH ELEM   00066  14  CACONDE         6   1.0"
            result = parse_elem_record(valid_elem, "test.dat", 1)
            @test result.constraint_id == 66

            valid_lim = "OPERUH LIM    00066  I       F                         600.00"
            result = parse_lim_record(valid_lim, "test.dat", 1)
            @test result.constraint_id == 66

            valid_var = "OPERUH VAR    03111 I       F                                          600.00"
            result = parse_var_record(valid_var, "test.dat", 1)
            @test result.constraint_id == 3111
        end
    end
    
    @testset "Parser Error Context - All Fields Present" begin
        @testset "File path included in error" begin
            err = ParserError("msg", "/path/to/TERM.DAT", 1, "content")
            @test occursin("TERM.DAT", err.file)
        end

        @testset "Line number included in error" begin
            invalid_line = "CADUNIDT 001 0012024 01 01 00 0       100.0      200.0"
            
            try
                parse_cadunidt(invalid_line, "test.dat", 999)
            catch e
                @test e.line == 999
            end
        end

        @testset "Line content included in error" begin
            invalid_line = "CADUNIDT 001 0012024 01 01 00 0       100.0      200.0"
            
            try
                parse_cadunidt(invalid_line, "test.dat", 1)
            catch e
                @test e.content == invalid_line
            end
        end

        @testset "Error message is informative" begin
            invalid_line = "CADUNIDT 001 0012024 01 01 00 0       100.0      200.0"
            
            try
                parse_cadunidt(invalid_line, "test.dat", 1)
            catch e
                # Should contain specific values, not generic message
                @test occursin("200.0", e.msg) || occursin("100.0", e.msg)
            end
        end
    end

    @testset "Validation Helpers Throw ParserError" begin
        @testset "validate_range throws ParserError" begin
            @test_throws ParserError validate_range(0, 1, 10, "test", file="f.dat", line_num=5)
            @test_throws ParserError validate_range(11, 1, 10, "test", file="f.dat", line_num=5)
        end

        @testset "validate_positive throws ParserError" begin
            @test_throws ParserError validate_positive(0, "test", file="f.dat", line_num=5)
            @test_throws ParserError validate_positive(-1, "test", file="f.dat", line_num=5)
        end

        @testset "validate_nonnegative throws ParserError" begin
            @test_throws ParserError validate_nonnegative(-1, "test", file="f.dat", line_num=5)
            @test_throws ParserError validate_nonnegative(-0.001, "test", file="f.dat", line_num=5)
        end
    end

    @testset "simul.jl Error Handling" begin
        # Note: SIMUL is legacy/deprecated but we test error handling for completeness
        # Format: Col 5-6 (day), 8-9 (hour), 11 (half-hour), etc.
        
        @testset "Invalid header throws ParserError" begin
            # Non-numeric day field at columns 5-6
            invalid_header = "    XX  00 0  01 2024 1"
            
            try
                parse_simul_header(invalid_header, "simul.dat", 1)
                @test false  # Should not reach here
            catch e
                @test isa(e, ParserError)
                @test e.file == "simul.dat"
                @test e.line == 1
            end
        end

        @testset "Invalid DISC record throws ParserError" begin
            # Non-numeric day field at columns 5-6
            invalid_disc = "    XX  00 0    1.0 1"
            
            try
                parse_disc_record(invalid_disc, "simul.dat", 5)
                @test false  # Should not reach here
            catch e
                @test isa(e, ParserError)
                @test e.file == "simul.dat"
                @test e.line == 5
            end
        end

        @testset "Invalid VOLI record throws ParserError" begin
            # Non-numeric plant number at columns 5-7
            invalid_voli = "    XXXXXXXXXXX    50.0"
            
            try
                parse_voli_record(invalid_voli, "simul.dat", 10)
                @test false  # Should not reach here
            catch e
                @test isa(e, ParserError)
                @test e.file == "simul.dat"
                @test e.line == 10
            end
        end

        @testset "Invalid OPER record throws ParserError" begin
            # Non-numeric plant number at columns 5-7
            invalid_oper = "    XXXXXXXXXXX"
            
            try
                parse_oper_record(invalid_oper, "simul.dat", 15)
                @test false  # Should not reach here
            catch e
                @test isa(e, ParserError)
                @test e.file == "simul.dat"
                @test e.line == 15
            end
        end

        @testset "Valid simul records parse successfully" begin
            # Valid header: day=01 at col 5-6, hour=00 at col 8-9, month=01 at col 14-15, year=2024 at col 18-21
            valid_header = "    01  00 0  01 2024 1"
            result = parse_simul_header(valid_header, "simul.dat", 1)
            @test result.start_day == 1
            @test result.start_year == 2024

            # Valid DISC: day=01, hour=00, duration=1.0 at col 15-19
            valid_disc = "    01  00 0    1.0 1"
            result = parse_disc_record(valid_disc, "simul.dat", 1)
            @test result.day == 1
            @test result.duration == 1.0
        end
    end

    @testset "renovaveis.jl Error Handling" begin
        @testset "Invalid record type throws ParserError" begin
            # Wrong record type
            invalid_record = "WRONG;1;Plant Name;100.0;0.5;0;"
            
            try
                parse_renovaveis_record(invalid_record, "renovaveis.dat", 1)
                @test false  # Should not reach here
            catch e
                @test isa(e, ParserError)
                @test !isa(e, MethodError)
                @test e.file == "renovaveis.dat"
                @test e.line == 1
            end
        end

        @testset "Too few fields throws ParserError" begin
            # Only 3 fields instead of required 6
            insufficient_fields = "EOLICA;1;Plant Name;"
            
            try
                parse_renovaveis_record(insufficient_fields, "renovaveis.dat", 5)
                @test false  # Should not reach here
            catch e
                @test isa(e, ParserError)
                @test e.file == "renovaveis.dat"
                @test e.line == 5
            end
        end

        @testset "Non-numeric plant code throws ParserError" begin
            invalid_plant_code = "EOLICA;ABC;Plant Name;100.0;0.5;0;"
            
            try
                parse_renovaveis_record(invalid_plant_code, "renovaveis.dat", 10)
                @test false  # Should not reach here
            catch e
                @test isa(e, ParserError)
                @test e.file == "renovaveis.dat"
                @test e.line == 10
            end
        end

        @testset "Valid renovaveis record parses successfully" begin
            valid_record = "EOLICA;1;Test Plant;100.0;0.5;0;"
            result = parse_renovaveis_record(valid_record, "renovaveis.dat", 1)
            @test result.plant_code == 1
            @test result.plant_name == "Test Plant"
            @test result.pmax == 100.0
        end
    end

    @testset "Edge Cases" begin
        @testset "Empty content string is valid" begin
            # ParserError with empty content (for file-level errors)
            err = ParserError("File not found", "missing.dat", 0, "")
            @test err.content == ""
            @test err.line == 0
        end

        @testset "Very long line content preserved" begin
            long_line = "CADUNIDT 001 0012024 01 01 00 0       100.0      200.0" * repeat(" ", 100)
            try
                parse_cadunidt(long_line, "test.dat", 1)
            catch e
                @test e.content == long_line
            end
        end
    end
end
