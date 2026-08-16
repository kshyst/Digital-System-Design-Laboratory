// Controller for the Start/Load/Step/Done handshake.
module booth_control (Clk, RstN, Start, LastStep, Load, Step, Done);

    input wire Clk;
    input wire RstN; // asynchronous active-low reset
    input wire Start;
    input wire LastStep;
    output wire Load;
    output wire Step;
    output wire Done; // one-cycle result-valid pulse

    localparam IDLE = 2'd0, LOAD = 2'd1, CALC = 2'd2, REPORT = 2'd3;

    reg [1:0] State;

    always @(posedge Clk or negedge RstN) begin
        if (!RstN) State <= IDLE;
        else case (State)
            IDLE: State <= Start ? LOAD : IDLE;
            LOAD: State <= CALC;
            CALC: State <= LastStep ? REPORT : CALC;
            REPORT: State <= IDLE;
        endcase
    end

    assign Load = (State == LOAD);
    assign Step = (State == CALC);
    assign Done = (State == REPORT);

endmodule
