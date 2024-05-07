// Hash module
module hash #(parameter index = 0) (
  input logic [103:0] input_data,
  input logic reset,
  input logic clock,
  output logic [9:0] hash
);

  always_ff @(posedge clock or posedge reset)
    if (reset)
      hash <= 10'd0; // Clear hash on reset
    else
      hash <= input_data[9:0] ^ input_data[19:10] ^ input_data[29:20] ^
               input_data[39:30] ^ input_data[49:40] ^ input_data[59:50] ^
               input_data[69:60] ^ input_data[79:70] ^ input_data[89:80] ^
               input_data[99:90] ^ input_data[103:100] << 6; 

endmodule

