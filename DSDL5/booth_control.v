module booth_control (Clk, RstN, Start, LastStep, Load, Step, Done);

    input wire Clk;
    input wire RstN; // active low
    input wire Start; // start signal
    input wire LastStep; // indicates that the datapath is finished with the calculation
    output wire Load; // store operands
    output wire Step; // apply one step: one add/subtract + shift
    output wire Done; // pulse when the result is ready

    localparam IDLE = 2'd0, LOAD = 2'd1, CALC = 2'd2, REPORT = 2'd3;

    // FSM register
    reg [1:0] State;

    always @(posedge Clk or negedge RstN) begin
        if (!RstN) State <= IDLE;
        else case (State)
            // stay in IDLE state unless Start=1, then switch to LOAD state
            IDLE: State <= Start ? LOAD : IDLE;
            // LOAD initializes the circuit and loads the inputs
            // switch to CALC state after LOAD
            LOAD: State <= CALC;
            // stay in CALC state until LastStep=1, then switch to REPORT
            CALC: State <= LastStep ? REPORT : CALC;
            // switch to IDLE state after REPORT
            REPORT: State <= IDLE;
        endcase
    end

    // control signals are derived from the state
    assign Load = (State == LOAD);
    assign Step = (State == CALC);
    assign Done = (State == REPORT);

endmodule
