// Test vector from Appendix B — Cipher Example (https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197-upd1.pdf)

`timescale 1ns / 1ps

module top_tb;
reg CLK, RST;
reg [127:0] KEY, PLAINTEXT; 
wire [127:0] STATE, CIPHERTEXT;

top dut (
.clk(CLK), .rst(RST), 
.plaintext(PLAINTEXT), .key(KEY),
.state(STATE), .ciphertext(CIPHERTEXT)
);

initial 
begin 
    CLK = 1;
    forever #5 CLK = ~CLK;
end

integer k;
initial 
begin
    PLAINTEXT = 128'h32_43_f6_a8_88_5a_30_8d_31_31_98_a2_e0_37_07_34;
    KEY = 128'h2b_7e_15_16_28_ae_d2_a6_ab_f7_15_88_09_cf_4f_3c;
    
    RST =1; #20;
    RST =0; 
    #250; // 10+1 clock cycles = 11*10  


$finish;
end
endmodule
