// Exemplo inicial para a iCESugar Nano (iCE40LP1K-CM36).
// O bit mais significativo de um contador de 24 bits controla o LED onboard.
module top (
    input wire clk,
    output wire led
);

reg [23:0] counter = 24'd0;

always @(posedge clk) begin
    counter <= counter + 1'b1;
end

assign led = counter[23];

endmodule
