using Test
using DESSEM2Julia
using Printf

@testset "BATERIA Parser Tests" begin
    @testset "Single Record Parsing" begin
        # 1-3: Battery number (I3)
        # 5-16: Battery name (A12)
        # 20-21: Subsystem number (I2)
        # 25-34: Charging capacity (F10.0)
        # 40-49: Discharging capacity (F10.0)
        # 55-64: Energy capacity (F10.0)
        # 70-79: Initial energy (F10.0)
        # 85-94: Charging efficiency (F10.0)
        # 100-109: Discharging efficiency (F10.0)

        # Example line - carefully aligned to columns using Printf
        # %3d (1-3) space (4) %-12s (5-16) 3spaces (17-19) %2d (20-21) 3spaces (22-24) 
        # %10.1f (25-34) 5spaces (35-39) %10.1f (40-49) 5spaces (50-54) %10.1f (55-64) ...
        line = @sprintf(
            "%3d %-12s   %2d   %10.1f     %10.1f     %10.1f     %10.1f     %10.2f     %10.2f",
            1,
            "BATTERY_01",
            1,
            100.0,
            100.0,
            500.0,
            250.0,
            0.95,
            0.95
        )

        record = DESSEM2Julia.BateriaParser.parse_bateria_record(line, "test.dat", 1)

        @test record.battery_id == 1
        @test record.name == "BATTERY_01"
        @test record.subsystem_id == 1
        @test record.charging_capacity == 100.0
        @test record.discharging_capacity == 100.0
        @test record.energy_capacity == 500.0
        @test record.initial_energy == 250.0
        @test record.charging_efficiency == 0.95
        @test record.discharging_efficiency == 0.95
    end

    @testset "Optional Fields" begin
        # Line with only required fields
        line = @sprintf(
            "%3d %-12s   %2d   %10.1f     %10.1f     %10.1f",
            2,
            "BATTERY_02",
            2,
            50.0,
            50.0,
            200.0
        )

        record = DESSEM2Julia.BateriaParser.parse_bateria_record(line, "test.dat", 1)

        @test record.battery_id == 2
        @test record.name == "BATTERY_02"
        @test record.subsystem_id == 2
        @test record.charging_capacity == 50.0
        @test record.discharging_capacity == 50.0
        @test record.energy_capacity == 200.0
        @test record.initial_energy === nothing
        @test record.charging_efficiency === nothing
        @test record.discharging_efficiency === nothing
    end

    @testset "Full File Parsing" begin
        line1 = @sprintf(
            "%3d %-12s   %2d   %10.1f     %10.1f     %10.1f     %10.1f     %10.2f     %10.2f",
            1,
            "BATTERY_01",
            1,
            100.0,
            100.0,
            500.0,
            250.0,
            0.95,
            0.95
        )
        line2 = @sprintf(
            "%3d %-12s   %2d   %10.1f     %10.1f     %10.1f",
            2,
            "BATTERY_02",
            2,
            50.0,
            50.0,
            200.0
        )

        io = IOBuffer("""
        * Comment
        $line1
        $line2
        """)

        data = parse_bateria(io, "test.dat")

        @test length(data.records) == 2
        @test data.records[1].name == "BATTERY_01"
        @test data.records[2].name == "BATTERY_02"
    end
end
