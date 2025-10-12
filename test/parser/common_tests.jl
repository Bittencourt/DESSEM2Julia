using Test
using DESSEM2Julia
using DESSEM2Julia.ParserCommon
using Dates

@testset "ParserCommon - Basic Utilities" begin
    @testset "normalize_name" begin
        @test normalize_name("hidr.dat") == "HIDR.DAT"
        @test normalize_name("/path/to/TERM.DAT") == "TERM.DAT"
        @test normalize_name("C:\\Windows\\Path\\file.xxx") == "FILE.XXX"
        @test normalize_name("ALREADY_UPPER.DAT") == "ALREADY_UPPER.DAT"
    end

    @testset "strip_comments" begin
        @test strip_comments("DATA 123 * comment") == "DATA 123"
        @test strip_comments("  DATA 123  ") == "DATA 123"
        @test strip_comments("* only comment") == ""
        @test strip_comments("NO COMMENT") == "NO COMMENT"
        @test strip_comments("DATA # hash comment", comment_chars=["#"]) == "DATA"
        @test strip_comments("DATA ; semicolon", comment_chars=[";"]) == "DATA"
    end

    @testset "is_blank" begin
        @test is_blank("")
        @test is_blank("   ")
        @test is_blank("  * comment only")
        @test is_blank("*")
        @test !is_blank("DATA 123")
        @test !is_blank("  DATA  ")
    end

    @testset "is_comment_line" begin
        @test is_comment_line("* This is a comment")
        @test is_comment_line("  * Comment with leading space")
        @test is_comment_line("C Network comment")
        @test is_comment_line("  C  Comment")
        @test !is_comment_line("DATA 123")
        @test !is_comment_line("  DATA * inline comment")
        @test is_comment_line("", comment_chars=["*", "C"]) == false
    end
end

@testset "ParserCommon - Field Extraction" begin
    @testset "extract_field" begin
        line = "ABCDEFGHIJKLMNOP"
        @test extract_field(line, 1, 3) == "ABC"
        @test extract_field(line, 4, 7) == "DEFG"
        @test extract_field(line, 1, 1) == "A"
        @test extract_field(line, 16, 16) == "P"
        
        # Beyond line length
        @test extract_field(line, 20, 25) == ""
        @test extract_field(line, 10, 30) == "JKLMNOP"
        
        # With whitespace
        @test extract_field("  ABC  DEF  ", 1, 5) == "ABC"
        @test extract_field("  ABC  DEF  ", 6, 10) == "DEF"
    end

    @testset "FieldSpec" begin
        spec = FieldSpec(:test, 1, 5, Int; required=true, default=0)
        @test spec.name == :test
        @test spec.start_col == 1
        @test spec.end_col == 5
        @test spec.type == Int
        @test spec.required == true
        @test spec.default == 0
        
        # Test assertions
        @test_throws AssertionError FieldSpec(:bad, 0, 5, Int)  # col < 1
        @test_throws AssertionError FieldSpec(:bad, 5, 3, Int)  # end < start
    end

    @testset "extract_fields" begin
        specs = [
            FieldSpec(:num, 1, 3, Int; required=true),
            FieldSpec(:name, 5, 16, String; default=""),
            FieldSpec(:value, 17, 22, Float64; default=0.0)
        ]
        
        # Normal case
        line = "001 PLANT_A     123.45"
        result = extract_fields(line, specs)
        @test result.num == 1
        @test result.name == "PLANT_A"
        @test result.value == 123.45
        
        # With defaults
        line2 = "002 PLANT_B      "
        result2 = extract_fields(line2, specs)
        @test result2.num == 2
        @test result2.name == "PLANT_B"
        @test result2.value == 0.0
        
        # Missing required field
        line3 = "    PLANT_C      123.45"
        @test_throws ParserError extract_fields(line3, specs, file="test.dat", line_num=10)
    end
end

@testset "ParserCommon - Type Conversion" begin
    @testset "parse_int" begin
        @test parse_int("123") == 123
        @test parse_int("  456  ") == 456
        @test parse_int("001") == 1
        @test parse_int("0") == 0
        @test parse_int("-5") == -5
        
        @test parse_int("", allow_blank=true) === nothing
        @test_throws ArgumentError parse_int("")
        @test_throws ArgumentError parse_int("   ")
        @test_throws ArgumentError parse_int("abc")
    end

    @testset "parse_float" begin
        @test parse_float("123.45") == 123.45
        @test parse_float("  456.78  ") == 456.78
        @test parse_float("1.5E+02") == 150.0
        @test parse_float("1.5e-02") == 0.015
        @test parse_float("0.0") == 0.0
        @test parse_float("-123.45") == -123.45
        
        # Locale handling
        @test parse_float("123,45", decimal_char=',') == 123.45
        @test parse_float("1,5E+02", decimal_char=',') == 150.0
        
        @test parse_float("", allow_blank=true) === nothing
        @test_throws ArgumentError parse_float("")
        @test_throws ArgumentError parse_float("abc")
    end

    @testset "parse_string" begin
        @test parse_string("PLANT") == "PLANT"
        @test parse_string("  PLANT  ") == "PLANT"
        @test parse_string("PLANT NAME") == "PLANT NAME"
        
        @test parse_string("", allow_blank=true) === nothing
        @test parse_string("", allow_blank=false) == ""
        @test parse_string("   ") === nothing
    end
end

@testset "ParserCommon - Date/Time Parsing" begin
    @testset "parse_date" begin
        d = parse_date(15, 3, 2024)
        @test d == Date(2024, 3, 15)
        
        d2 = parse_date(1, 1, 2024)
        @test d2 == Date(2024, 1, 1)
        
        d3 = parse_date(31, 12, 2023)
        @test d3 == Date(2023, 12, 31)
    end

    @testset "parse_time" begin
        @test parse_time(0, 0) == Time(0, 0)
        @test parse_time(14, 0) == Time(14, 0)
        @test parse_time(14, 1) == Time(14, 30)
        @test parse_time(23, 1) == Time(23, 30)
        
        @test_throws AssertionError parse_time(24, 0)  # Invalid hour
        @test_throws AssertionError parse_time(-1, 0)  # Invalid hour
        @test_throws AssertionError parse_time(12, 2)  # Invalid half-hour
    end

    @testset "parse_datetime" begin
        dt = parse_datetime(15, 3, 2024, 14, 0)
        @test dt == DateTime(2024, 3, 15, 14, 0)
        
        dt2 = parse_datetime(15, 3, 2024, 14, 1)
        @test dt2 == DateTime(2024, 3, 15, 14, 30)
        
        # With defaults
        dt3 = parse_datetime(1, 1, 2024)
        @test dt3 == DateTime(2024, 1, 1, 0, 0)
    end

    @testset "parse_time_period" begin
        (start, finish) = parse_time_period(1, 0, 0, 1, 23, 1)
        @test start == (1, Time(0, 0))
        @test finish == (1, Time(23, 30))
        
        (start2, finish2) = parse_time_period(5, 12, 1, 7, 18, 0)
        @test start2 == (5, Time(12, 30))
        @test finish2 == (7, Time(18, 0))
    end
end

@testset "ParserCommon - Validation Helpers" begin
    @testset "validate_range" begin
        @test validate_range(5, 1, 10, "test") == 5
        @test validate_range(1, 1, 10, "test") == 1
        @test validate_range(10, 1, 10, "test") == 10
        
        @test_throws ParserError validate_range(0, 1, 10, "test", file="f.dat", line_num=5)
        @test_throws ParserError validate_range(11, 1, 10, "test", file="f.dat", line_num=5)
    end

    @testset "validate_positive" begin
        @test validate_positive(5, "test") == 5
        @test validate_positive(0.001, "test") == 0.001
        
        @test_throws ParserError validate_positive(0, "test", file="f.dat", line_num=5)
        @test_throws ParserError validate_positive(-1, "test", file="f.dat", line_num=5)
    end

    @testset "validate_nonnegative" begin
        @test validate_nonnegative(5, "test") == 5
        @test validate_nonnegative(0, "test") == 0
        @test validate_nonnegative(0.0, "test") == 0.0
        
        @test_throws ParserError validate_nonnegative(-1, "test", file="f.dat", line_num=5)
        @test_throws ParserError validate_nonnegative(-0.001, "test", file="f.dat", line_num=5)
    end
end

@testset "ParserCommon - Error Handling" begin
    @testset "ParserError" begin
        err = ParserError("Test error", "test.dat", 42, "problematic line")
        @test err.msg == "Test error"
        @test err.file == "test.dat"
        @test err.line == 42
        @test err.content == "problematic line"
        
        # Test error message formatting
        io = IOBuffer()
        showerror(io, err)
        msg = String(take!(io))
        @test occursin("test.dat:42", msg)
        @test occursin("Test error", msg)
        @test occursin("problematic line", msg)
    end
end

@testset "ParserCommon - File Reading" begin
    @testset "read_nonblank_lines" begin
        # Create temporary file
        mktempdir() do tmpdir
            testfile = joinpath(tmpdir, "test.dat")
            open(testfile, "w") do f
                write(f, "* Header comment\n")
                write(f, "\n")
                write(f, "DATA 001  VALUE1\n")
                write(f, "   \n")
                write(f, "DATA 002  VALUE2  * inline comment\n")
                write(f, "* Another comment\n")
                write(f, "DATA 003  VALUE3\n")
                write(f, "\n")
            end
            
            lines = read_nonblank_lines(testfile, skip_comments=true)
            @test length(lines) == 3
            @test lines[1] == "DATA 001  VALUE1"
            @test lines[2] == "DATA 002  VALUE2"
            @test lines[3] == "DATA 003  VALUE3"
            
            # Without skipping comments - note that comment-only lines are treated as blank
            lines2 = read_nonblank_lines(testfile, skip_comments=false)
            @test length(lines2) == 3  # Same as above - comment-only lines are considered blank
        end
    end
end

@testset "ParserCommon - Integration Example" begin
    # Simulate parsing a HIDR.DAT CADUSIH record
    line = "CADUSIH 001 CAMARGOS     04                   0.0        792.0      "
    
    specs = [
        FieldSpec(:record_type, 1, 7, String; required=true),
        FieldSpec(:plant_num, 9, 11, Int; required=true),
        FieldSpec(:plant_name, 13, 24, String; required=true),
        FieldSpec(:subsystem, 26, 27, Int; required=true),
        FieldSpec(:min_volume, 47, 49, Float64; default=0.0),
        FieldSpec(:max_volume, 58, 62, Float64; required=true),
    ]
    
    result = extract_fields(line, specs, file="HIDR.DAT", line_num=100)
    
    @test result.record_type == "CADUSIH"
    @test result.plant_num == 1
    @test result.plant_name == "CAMARGOS"
    @test result.subsystem == 4
    @test result.min_volume == 0.0
    @test result.max_volume == 792.0
    
    # Validate parsed values
    @test validate_positive(result.plant_num, "plant_num") == 1
    @test validate_nonnegative(result.min_volume, "min_volume") == 0.0
    @test validate_positive(result.max_volume, "max_volume") == 792.0
end
